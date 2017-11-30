//
//  AMServiceProvider.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation
import os.log

public typealias RequestCompletion = (Any?, Error?) -> ()
public typealias RequestProgress = (Double) -> ()

open class AMServiceProvider : AFHTTPSessionManager {
    
    public var responserKey: String?
    public var authorizationToken: String?
    public var enabledLogging: Bool = true
    
    private var loginProcess: ((RequestCompletion)->())?
    
    public init(baseURL url: URL,
                        loginProcess: ((RequestCompletion)->())?,
                        requestSerializer: AFHTTPRequestSerializer,
                        responseSerializer: AFHTTPResponseSerializer) {
        
        super.init(baseURL: url, sessionConfiguration: nil)
        self.loginProcess = loginProcess
        self.requestSerializer = requestSerializer
        self.responseSerializer = responseSerializer
    }
    
    public convenience init(baseURL url: URL, loginProcess: ((RequestCompletion)->())?) {
        self.init(baseURL: url, loginProcess: loginProcess, requestSerializer:AFJSONRequestSerializer(), responseSerializer: AMJSONResponseSerializer())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func send(_ request: AMServiceRequest) -> URLSessionDataTask? {
        return internalSend(request, progress: nil, completion: nil) as? URLSessionDataTask
    }
        
    public func sendWith<T: AMServiceRequest>(_ request: T, completion: @escaping (T, Error?)->()) -> URLSessionDataTask? {
        return internalSend(request, progress: nil, completion: completion) as? URLSessionDataTask
    }
    
    public func uploadFile<T: AMFileRequest>(_ request: T, progress: RequestProgress?, completion: ((T, Error?)->())?) -> URLSessionUploadTask? {
        return internalSend(request, progress: progress, completion: completion) as? URLSessionUploadTask
    }
    
    public func downloadFile<T: AMFileRequest>(_ request: T, progress: RequestProgress?, completion: ((T, Error?)->())?) -> URLSessionDownloadTask? {
        return internalSend(request, progress: progress, completion: completion) as? URLSessionDownloadTask
    }
    
    // by default it checks error for 401 code
    open func isFailedAuthorization(_ request: AMServiceRequest, error: AMRequestError) -> Bool {
        return error.code == AMHTTPStatusCodes.HTTP_UNAUTORIZED.rawValue
    }
    
    open func requestWillSend(_ request: inout URLRequest, serviceRequest: AMServiceRequest) {
        let requestId = UUID().uuidString
        request.setValue(requestId, forHTTPHeaderField: "X-Request-id")
        if let token = authorizationToken {
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        }
        log(message: "sending request with id:\(requestId)")
    }
}

fileprivate extension AMServiceProvider {
    
    func log(message: String) {
        if enabledLogging {
            os_log("@", message)
        }
    }
    
    func internalSend<T: AMServiceRequest>(_ originalRequest: T, progress: RequestProgress?, completion: ((T, Error?)->())?) -> URLSessionTask? {
        return enque(originalRequest, progress:progress, completion: { (innerRequest, error) in
            
            if let error = error as? AMRequestError, self.isFailedAuthorization(innerRequest, error: error) {
                
                _ = AMOperationCombiner.run(block: { (completion, _) -> AnyObject? in
                    
                    if let loginProcess = self.loginProcess {
                        loginProcess(completion)
                    } else {
                        completion(nil, error)
                    }
                    return nil
                    
                }, completion: { (request, error) in
                    
                    if error == nil {
                        _ = self.internalSend(innerRequest, progress: progress, completion: completion)
                    } else {
                        completion?(innerRequest, error)
                    }
                    
                }, progress: nil, key: "AMServiceProviderInnerRelogin")
                
            } else {
                completion?(innerRequest, error)
            }
            
        })
    }
    
    func requestFor(_ serviceRequest: AMServiceRequest) throws -> URLRequest {
        var error: NSError?
        
        var request: NSMutableURLRequest?
        
        if let fileRequest = serviceRequest as? AMFileRequest, fileRequest.isUpload {
            request = requestSerializer.multipartFormRequest(withMethod: fileRequest.method(),
                                                             urlString: URL(string: fileRequest.path(), relativeTo: baseURL)!.absoluteString,
                                                             parameters: fileRequest.requestDictionary(),
                                                             constructingBodyWith: { (formData) in
                                                            
                                                                if let path = fileRequest.filePath() {
                                                                
                                                                    try? formData.appendPart(withFileURL: URL(fileURLWithPath: path),
                                                                                             name: fileRequest.formFileField())
                                                                
                                                                } else if let data = fileRequest.fileData, let name = fileRequest.fileName {
                                                                
                                                                    formData.appendPart(withFileData: data,
                                                                                        name: fileRequest.formFileField(),
                                                                                        fileName: name,
                                                                                        mimeType: fileRequest.mimeType())
                                                                }
                                                            }, error: &error)
            
        } else {
            request = requestSerializer.request(withMethod: serviceRequest.method(),
                                                urlString: URL(string:serviceRequest.path(), relativeTo:baseURL!)!.absoluteString,
                                                parameters: serviceRequest.requestDictionary(),
                                                error: &error)
        }
        
        if let error = error {
            throw error
        }
        if request == nil {
            throw AMRequestError(code: 0, description: "Cannot send request")
        }
        return request! as URLRequest
    }
    
    func enque<T: AMServiceRequest>(_ request: T, progress:RequestProgress?, completion: @escaping (T, Error?)->()) -> URLSessionTask? {
        
        var task: URLSessionTask?
        var urlRequest: URLRequest
        
        do {
            urlRequest = try requestFor(request)
            
            if let contentType = request.acceptableContentType() {
                urlRequest.setValue(contentType, forHTTPHeaderField: "Accept")
            }
            requestWillSend(&urlRequest, serviceRequest: request)
            request.requestWillSend(request: &urlRequest)
            
            if let fileRequest = request as? AMFileRequest {
                
                let updateProgress = { (progressObj: Progress) in
                    DispatchQueue.main.async {
                        progress?(progressObj.fractionCompleted)
                    }
                }
                
                if fileRequest.isUpload {
                    
                    task = uploadTask(withStreamedRequest: urlRequest, progress: updateProgress, completionHandler: { (response, object, error) in
                        let httpResponse = response as! HTTPURLResponse
                        self.process(response: httpResponse, object: object, error: error, request: request, completion: completion)
                    })
                } else {
                    
                    if let filePath = fileRequest.filePath() {
                        
                        task = downloadTask(with: urlRequest, progress: updateProgress, destination: { (targetURL, _) -> URL in
                            return URL(fileURLWithPath: filePath)
                        }, completionHandler: { (response, url, error) in
                            
                            let httpResponse = response as! HTTPURLResponse
                            self.process(response: httpResponse, object: nil, error: error, request: request, completion: completion)
                        })
                        
                    } else {
                        task = dataTask(with: urlRequest, uploadProgress: nil, downloadProgress: updateProgress, completionHandler: { (response, object, error) in
                        
                            if error == nil, let data = object as? Data {
                                fileRequest.fileData = data
                            }
                            let httpResponse = response as! HTTPURLResponse
                            self.process(response: httpResponse, object: object, error: error, request: request, completion: completion)
                        })
                    }
                }
            } else {
                
                task = dataTask(with: urlRequest, uploadProgress: nil, downloadProgress: nil, completionHandler: { (response, object, error) in
                    
                    let httpResponse = response as! HTTPURLResponse
                    self.process(response: httpResponse, object: object, error: error, request: request, completion: completion)
                })
            }
            
        } catch {
            completion(request, error)
            return nil
        }
        
        log(message: "request url: \(String(describing: urlRequest.url?.absoluteString))")
        log(message: "request headers: \(String(describing: urlRequest.allHTTPHeaderFields))")
        
        if let body = urlRequest.httpBody, request as? AMFileRequest == nil {
            log(message: "request body: \(String(data:body, encoding:String.Encoding(rawValue: requestSerializer.stringEncoding)) ?? "Cannot parse body")")
        }
        
        task?.resume()
        
        return task
    }
    
    func process<T: AMServiceRequest>(response: HTTPURLResponse, object: Any?, error: Error?, request: T, completion: @escaping (T, Error?)->()) {
        
        log(message: "response code: \(response.statusCode)")
        log(message: "response headers: \(response.allHeaderFields)")
        
        var resultError = error
        
        if resultError == nil {
            resultError = request.validate(response: object, httpResponse: response)
        }
        
        if let mime = response.mimeType, mime.hasPrefix("application") || mime.hasPrefix("text") {
            if let object = object as? [AnyHashable : Any] {
                log(message: "Response body: \(object)")
            } else if let object = object as? [Any] {
                log(message: "Response body: \(object)")
            } else if let object = object as? Data {
                log(message: "Response body: \(String(data:object, encoding:String.Encoding(rawValue: requestSerializer.stringEncoding)) ?? "Cannot parse body")")
            }
        }
        
        if let error = resultError {
            log(message: "request error: \(error.localizedDescription)")
            
            resultError = request.convert(responseError: error)
            
            completion(request, resultError)
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            
            var validObject = object
            
            if let key = self.responserKey, let dict = object as? [AnyHashable:Any] {
                validObject = dict[key]
            }
            if let object = validObject {
                request.process(response: object)
            }
            
            DispatchQueue.main.async {
                completion(request, nil)
            }
        }
    }
}

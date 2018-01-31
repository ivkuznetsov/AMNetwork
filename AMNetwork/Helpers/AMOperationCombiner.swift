//
//  AMOperationCombiner.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

public typealias RequestCompletion<T> = (T, Error?)->()

public final class AMOperationCombiner {
    
    private var processingRequests: [String : [String : [AnyObject]]] = [:]
    
    public func run<T>(_ type: T.Type, key: String?, completion: RequestCompletion<T>?, progress: RequestProgress?, closure: (@escaping RequestCompletion<T>, @escaping RequestProgress) -> AnyObject?) -> AnyObject? {
        
        if let key = key {
        
            var dict = processingRequests[key]
            
            var wrappedCompletion: ((Any, Error?)->())?
            
            if let completion = completion {
                wrappedCompletion = { (request, error) in
                    completion(request as! T, error)
                }
            }
            
            if var dict = dict {
                insertBlock(block: wrappedCompletion as AnyObject?, dict: &dict, key: "completion")
                insertBlock(block: progress as AnyObject?, dict: &dict , key: "progress")
                processingRequests[key] = dict
                return dict["operation"]?.first
            }
            
            dict = [:]
            insertBlock(block: wrappedCompletion as AnyObject?, dict: &dict!, key: "completion")
            insertBlock(block: progress as AnyObject?, dict: &dict!, key: "progress")
            processingRequests[key] = dict
            
            let operation = closure({ (object, error) in
                
                if let dict = self.processingRequests[key], let blocks = dict["completion"] {
                    blocks.forEach {
                        if let block = $0 as? (Any, Error?)->() {
                            block(object, error)
                        }
                    }
                    self.processingRequests[key] = nil
                }
                
            }) { (progress) in
                
                if let dict = self.processingRequests[key], let blocks = dict["progress"] {
                    blocks.forEach { (object) in
                        if let block = object as? RequestProgress {
                            block(progress)
                        }
                    }
                }
            }
            
            if let oper = operation, var dict = processingRequests[key] {
                dict["operation"] = [oper]
                processingRequests[key] = dict
            }
            
            return operation
        } else {
            return closure({ (object, error) in
                completion?(object, error)
            }, { (progressValue) in
                progress?(progressValue)
            })
        }
    }
    
    private func insertBlock(block: AnyObject?, dict: inout [String : [AnyObject]], key: String) {
        var blocks = dict[key] ?? []
        
        if let block = block {
            blocks.append(block)
        }
        dict[key] = blocks
    }
}

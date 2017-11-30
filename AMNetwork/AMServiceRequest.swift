//
//  AMServiceRequest.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

open class AMServiceRequest {
    
    public init() {
        
    }
    
    open func acceptableContentType() -> String? {
        return "application/json"
    }
    
    open func method() -> String {
        return "POST"
    }
    
    open func path() -> String {
        return "(request_path_here)"
    }
    
    open func requestDictionary() -> [String : Any] {
        return [:]
    }
    
    open func process(response: Any) {
        
    }
    
    open func reuseId() -> String? {
        return nil
    }
    
    open func canAskLogin() -> Bool {
        return true
    }
    
    open func requestWillSend(request: inout URLRequest) {
        
    }
    
    open func convert(responseError: Error) -> Error {
        return responseError
    }
    
    open func validate(response: Any?, httpResponse: HTTPURLResponse) -> AMRequestError? {
        
        let acceptableCodes = IndexSet(integersIn: 200..<301)
        
        if !acceptableCodes.contains(httpResponse.statusCode) {
            return AMRequestError(code: httpResponse.statusCode, description: "Some server error occured")
        }
        return nil
    }
}

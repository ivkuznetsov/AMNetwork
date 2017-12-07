//
//  AMServiceRequest.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

@objc public protocol AMServiceRequest {
    
    func acceptableContentType() -> String
    
    func method() -> String
    
    func path() -> String
    
    func requestDictionary() -> [String : Any]?
    
    func process(response: Any)
    
    func canAskLogin() -> Bool
}

@objc public protocol RequestReusing {
    
    func reuseId() -> String?
}

@objc public protocol RequestErrorConverting {
    
    func convert(responseError: Error) -> Error?
    
    func validate(response: Any?, httpResponse: HTTPURLResponse) -> Error?
}

@objc public protocol RequestCustomizing {
    
    func requestWillSend(_ request: NSMutableURLRequest)
}

extension AMServiceRequest {
    
    func reusing() -> RequestReusing? {
        return self as? RequestReusing
    }
    
    func errorConverting() -> RequestErrorConverting? {
        return self as? RequestErrorConverting
    }
    
    func customizing() -> RequestCustomizing? {
        return self as? RequestCustomizing
    }
}

//
//  AMJSONResponseSerializer.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

open class AMJSONResponseSerializer: AFJSONResponseSerializer {
    
    public override init() {
        super.init()
        self.acceptableStatusCodes = IndexSet(integersIn: 200..<551)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        let object = super.responseObject(for: response, data: data, error: error)
        
        if let pointer = error, let err = pointer.pointee, err.domain == AFURLResponseSerializationErrorDomain && err.code == NSURLErrorCannotDecodeContentData {
            pointer.pointee = nil
            
            return data
        }
        return object
    }
    
}

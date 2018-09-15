//
//  AMRequestError.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

@objc open class AMRequestError: NSError {
    
    @objc public override init(domain: String, code: Int, userInfo dict: [String : Any]? = nil) {
        super.init(domain: domain, code: code, userInfo: dict)
    }
    
    @objc public init(code: Int, description: String) {
        super.init(domain: "amnetwork.com", code: code, userInfo: [NSLocalizedDescriptionKey : description])
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

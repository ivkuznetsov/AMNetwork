//
//  AMRequestError.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

open class AMRequestError : LocalizedError {
    
    public var errorDescription : String?
    public var code: Int
    
    init(code: Int) {
        self.code = code;
    }
    
    public convenience init(code: Int, description: String) {
        self.init(code: code)
        self.errorDescription = description
    }
}

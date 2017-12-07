//
//  AMBaseFileRequest.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 12/7/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

open class AMBaseFileRequest: AMBaseRequest, AMFileRequest {
    
    open var fileData: Data?
    open var fileName: String?
    
    open func filePath() -> String? {
        return nil
    }
}

extension AMBaseFileRequest: AMFileUpload {
    
    public func mimeType() -> String {
        return "application/octet-stream"
    }
    
    public func formFileField() -> String {
        return "data[file]"
    }
}

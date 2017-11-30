//
//  AMFileRequest.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

open class AMFileRequest: AMServiceRequest {
    
    public var isUpload: Bool = true
    
    //if filePath returns nil, all data should be here
    public var fileData: Data?
    public var fileName: String?
    
    open func filePath() -> String? {
        return nil
    }
    
    open func mimeType() -> String {
        return "application/octet-stream"
    }
    
    open override func acceptableContentType() -> String? {
        return isUpload ? super.acceptableContentType() : nil
    }
    
    open func formFileField() -> String {
        return "data[file]"
    }
}

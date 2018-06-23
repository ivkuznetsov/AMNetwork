//
//  AMFileRequest.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

@objc public protocol AMFileRequest: AMServiceRequest {
    
    //destination for download, source for upload
    func filePath() -> String?
    
    //if filePath returns nil, all data should be here
    var fileData: Data? { get set }
    var fileName: String? { get set }
}

@objc public protocol AMFileUpload: AMFileRequest {
    
    func mimeType() -> String
    
    func formFileField() -> String
}

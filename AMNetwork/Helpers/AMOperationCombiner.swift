//
//  AMOperationCombiner.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

public final class AMOperationCombiner {
    
    private static let shared = AMOperationCombiner()
    
    private var processingRequests: [String : [String : [AnyObject]]] = [:]
    
    public class func run(block: (@escaping RequestCompletion, @escaping RequestProgress) -> AnyObject?, completion: RequestCompletion?, progress: RequestProgress?, key: String?) -> AnyObject? {
        
        if let key = key {
        
            var dict = self.shared.processingRequests[key]
            
            if var dict = dict {
                insertBlock(block: completion as AnyObject?, dict: &dict, key: "completion")
                insertBlock(block: progress as AnyObject?, dict: &dict , key: "progress")
                return dict["operation"]?.first
            }
            
            dict = [:]
            insertBlock(block: completion as AnyObject?, dict: &dict!, key: "completion")
            insertBlock(block: progress as AnyObject?, dict: &dict!, key: "progress")
            self.shared.processingRequests[key] = dict
            
            let operation = block({ (object, error) in
                
                if let dict = shared.processingRequests[key], let blocks = dict["completion"] {
                    blocks.forEach {
                        if let block = $0 as? RequestCompletion {
                            block(object, error)
                        }
                    }
                    shared.processingRequests[key] = nil
                }
                
            }) { (progress) in
                
                if let dict = shared.processingRequests[key], let blocks = dict["progress"] {
                    blocks.forEach { (object) in
                        if let block = object as? RequestProgress {
                            block(progress)
                        }
                    }
                }
            }
            
            if let oper = operation {
                dict!["operation"] = [oper]
            }
            
            return operation
        } else {
            return block({ (object, error) in
                completion?(object, error)
            }, { (progressValue) in
                progress?(progressValue)
            })
        }
    }
    
    private class func insertBlock(block: AnyObject?, dict: inout [String : [AnyObject]], key: String) {
        var blocks = dict[key]
        
        if blocks == nil {
            blocks = []
        }
        if let block = block, let innerBlocks = blocks, !innerBlocks.contains(where: { $0 === block }) {
            blocks?.append(block)
        }
        dict[key] = blocks!
    }
}

//
//  AMOperationCombiner.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

public typealias RequestCompletion<T> = (T, Error?)->()

private class CompletionWrapper<T> {
    var completion: (T, Error?)->()
    
    init?(completion: ((T, Error?)->())?) {
        if let completion = completion {
            self.completion = completion
        } else {
            return nil
        }
    }
}

private class ProgressWrapper {
    var progress: (Double)->()
    
    init?(progress: ((Double)->())?) {
        if let progress = progress {
            self.progress = progress
        } else {
            return nil
        }
    }
}

public final class AMOperationCombiner {
    
    private var processingRequests: [String : [String : [AnyObject]]] = [:]
    
    public func run<T>(_ type: T.Type, key: String?, completion: RequestCompletion<T>?, progress: RequestProgress?, closure: (@escaping RequestCompletion<T>, @escaping RequestProgress) -> AnyObject?) -> AnyObject? {
        
        if let key = key {
        
            var dict = processingRequests[key]
            
            let completionWrapper = CompletionWrapper<T>(completion: completion)
            let progressWrapper = ProgressWrapper(progress: progress)
            
            if var dict = dict {
                insertBlock(block: completionWrapper, dict: &dict, key: "completion")
                insertBlock(block: progressWrapper, dict: &dict , key: "progress")
                processingRequests[key] = dict
                return dict["operation"]?.first
            }
            
            dict = [:]
            insertBlock(block: completionWrapper, dict: &dict!, key: "completion")
            insertBlock(block: progressWrapper, dict: &dict!, key: "progress")
            processingRequests[key] = dict
            
            let operation = closure({ (object, error) in
                
                if let dict = self.processingRequests[key], let blocks = dict["completion"] {
                    blocks.forEach {
                        if let block = $0 as? CompletionWrapper<T> {
                            block.completion(object, error)
                        }
                    }
                    self.processingRequests[key] = nil
                }
                
            }) { (progress) in
                
                if let dict = self.processingRequests[key], let blocks = dict["progress"] {
                    blocks.forEach { (object) in
                        if let block = object as? ProgressWrapper {
                            block.progress(progress)
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

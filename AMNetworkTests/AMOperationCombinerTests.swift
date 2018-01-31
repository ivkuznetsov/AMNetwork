//
//  AMOperationCombinerTests.swift
//  AMNetworkTests
//
//  Created by Ilya Kuznetsov on 1/31/18.
//  Copyright © 2018 Ilya Kuznetsov. All rights reserved.
//

import XCTest
@testable import AMNetwork

class AMOperationCombinerTests: XCTestCase {
    
    var combiner: AMOperationCombiner!
    
    override func setUp() {
        super.setUp()
        combiner = AMOperationCombiner()
    }
    
    func testCompletion() {
        let test = expectation(description: "Completion performed")
        
        _ = combiner.run(String.self, key: nil, completion: { (_, _) in
            
            test.fulfill()
            
        }, progress: nil) { (completion, progress) -> AnyObject? in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                completion("", nil)
            })
            return nil
        }
        wait(for: [test], timeout: 1.0)
    }
    
    func testCombining() {
        let test = expectation(description: "Completion performed")
        
        var closureRun = false
        var completions = 0
        
        for _ in 0..<10 {
            _ = combiner.run(String.self, key: "key", completion: { (_, _) in
                
                completions += 1
                if completions == 10 {
                    test.fulfill()
                }
                
            }, progress: nil) { (completion, progress) -> AnyObject? in
                
                XCTAssertFalse(closureRun)
                closureRun = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    completion("", nil)
                })
                return nil
            }
        }
        wait(for: [test], timeout: 5.0)
    }
    
    func testOperation() {
        var operationUid: UUID?
        for _ in 0..<10 {
            let currentUid = combiner.run(String.self, key: "key", completion: nil, progress: nil) { (completion, progress) -> AnyObject? in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    completion("", nil)
                })
                return UUID() as AnyObject
            } as! UUID
            if operationUid == nil {
                operationUid = currentUid
            } else {
                XCTAssert(operationUid!.uuidString == currentUid.uuidString)
            }
        }
    }
    
    func testProgress() {
        let test = expectation(description: "Progress performed")
        
        var progressPerforms = 0
        for _ in 0..<10 {
            _ = combiner.run(String.self, key: "key", completion: nil, progress: { (progress) in
                
                progressPerforms += 1
                
            }) { (completion, progress) -> AnyObject? in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    
                    progress(0.5)
                    
                    DispatchQueue.main.async {
                        
                        completion("", nil)
                        XCTAssert(progressPerforms == 10)
                        test.fulfill()
                    }
                })
                return nil
            }
        }
        wait(for: [test], timeout: 5.0)
    }
}

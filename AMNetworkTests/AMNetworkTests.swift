//
//  AMNetworkTests.swift
//  AMNetworkTests
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import XCTest
@testable import AMNetwork

class SampleRequest: AMBaseRequest {
    
    var didProcess: (()->())?
    var mockError: (()->(Error?))?
    var mockReuseId: (()->(String))?
    
    override func method() -> String { return "GET" }
    
    override func path() -> String { return "" }
    
    override func reuseId() -> String? {
        return mockReuseId?()
    }
    
    override func validate(response: Any?, httpResponse: HTTPURLResponse) -> Error? {
        didProcess?()
        if let error = mockError?() {
           return error
        }
        return super.validate(response: response, httpResponse: httpResponse)
    }
}

class AMNetworkTests: XCTestCase {
    
    let baseURL = URL(string: "https://httpbin.org")!
    
    var service: AMServiceProvider!
    
    override func setUp() {
        service = AMServiceProvider(baseURL: baseURL, loginProcess: nil)
        super.setUp()
    }
    
    func testSendRequest() {
        let test = expectation(description: "Request has been sent")
        let task = service.sendWith(SampleRequest()) { (request, error) in
            
            XCTAssertNil(error)
            test.fulfill()
        }
        XCTAssertNotNil(task)
        wait(for: [test], timeout: 1.0)
    }
    
    func testRequestError() {
        let test = expectation(description: "Request has been sent and got error")
        let request = SampleRequest()
        request.mockError = {
            return AMRequestError(code: 0, description: "Sample")
        }
        let task = service.sendWith(request) { (request, error) in
            
            XCTAssertNotNil(error)
            test.fulfill()
        }
        XCTAssertNotNil(task)
        wait(for: [test], timeout: 1.0)
    }
    
    func testReusableFeature() {
        let test = expectation(description: "Request has been sent single time")
        
        var requestCompleted = 0
        var requestProcessing = 0
        for _ in 0..<10 {
            let request = SampleRequest()
            request.mockReuseId = {
                return "request"
            }
            request.didProcess = {
                requestProcessing += 1
            }
            _ = service.sendWith(request) { (request, error) in
                requestCompleted += 1
                if requestCompleted == 10 {
                    XCTAssert(requestProcessing == 1)
                    test.fulfill()
                }
            }
        }
        wait(for: [test], timeout: 5.0)
    }
    
    func testRefreshAuth() {
        let test = expectation(description: "Login has been run single time")
        
        var authRefreshed = false
        var loginAsked = 0
        let service = AMServiceProvider(baseURL: baseURL) { (didLogin) in
            loginAsked = 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                authRefreshed = true
                didLogin(nil)
            })
        }
        
        var requestCompleted = 0
        for _ in 0..<10 {
            let request = SampleRequest()
            request.mockError = {
                return authRefreshed ? nil : AMRequestError(code: 401, description: "Sample")
            }
            
            _ = service.sendWith(request) { (request, error) in
                
                if error == nil {
                    requestCompleted += 1
                }
                if requestCompleted == 10 {
                    XCTAssert(loginAsked == 1)
                    test.fulfill()
                }
            }
        }
        wait(for: [test], timeout: 5.0)
    }
    
    func testRefreshAuthFailed() {
        let test = expectation(description: "Login has been run single time")
        
        var loginAsked = 0
        let service = AMServiceProvider(baseURL: baseURL) { (didLogin) in
            loginAsked = 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                didLogin(AMRequestError(code: 0, description: "error"))
            })
        }
        
        var requestCompleted = 0
        for _ in 0..<10 {
            let request = SampleRequest()
            request.mockError = {
                return AMRequestError(code: 401, description: "Sample")
            }
            
            _ = service.sendWith(request) { (request, error) in
                
                if error != nil {
                    requestCompleted += 1
                }
                if requestCompleted == 10 {
                    XCTAssert(loginAsked == 1)
                    test.fulfill()
                }
            }
        }
        wait(for: [test], timeout: 5.0)
    }
}

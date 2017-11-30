//
//  AMHTTPStatusCodes.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 11/21/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

public enum AMHTTPStatusCodes: Int {
    case HTTP_OK = 200                        //all ok
    
    case HTTP_BAD_REQUEST = 400                //wrong request
    case HTTP_UNAUTORIZED = 401                //needs autorization
    case HTTP_FORBIDDEN = 403                //service refused to fulfill the request(for example: if user doesn't have enough privileges)
    case HTTP_NOT_FOUND = 404                //resource is not found
    
    case HTTP_MOVED_PERMANENTLY = 301        //used for redirects
    case HTTP_FOUND = 302
    
    case HTTP_INTERNAL_SERVER_ERROR = 500    //service exception
    case HTTP_NOT_IMPLEMENTED = 501            //method is not implemented
    case HTTP_BAD_GATEWAY = 502                //502, 503 and 504 - gateway problems
    case HTTP_SERVICE_UNAVAILABLE = 503
    case HTTP_GATEWAY_TIMEOUT = 504
}

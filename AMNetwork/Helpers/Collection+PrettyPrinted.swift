//
//  Collection+PrettyPrinted.swift
//  AMNetwork
//
//  Created by Ilya Kuznetsov on 12/7/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

public extension Collection {
    
    public func json() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
            guard let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) else {
                print("Can't create string with data.")
                return "{}"
            }
            return jsonString
        } catch let parseError {
            print("json serialization error: \(parseError)")
            return "{}"
        }
    }
}

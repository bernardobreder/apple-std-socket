//
//  StdSocketConfig.swift
//  codegenv
//
//  Created by Bernardo Breder on 12/11/16.
//
//

import Foundation

open class StdSocketConfig {
    
    public let port: Int
    
    public var queueSize: Int = 100
    
    public init(port: Int = 8080) {
        self.port = port
    }
    
}

 //
//  SocketAddress.swift
//  netunix
//
//  Created by Bernardo Breder on 30/10/16.
//  Copyright © 2016 Bernardo Breder. All rights reserved.
//

import Foundation

public extension sockaddr_storage {
    
    public func asAddr() -> sockaddr {
        
        var temp = self
        let addr = withUnsafePointer(to: &temp) {
            return UnsafeRawPointer($0)
        }
        return addr.assumingMemoryBound(to: sockaddr.self).pointee
        
    }
    
}

public extension sockaddr_in {
    
    public func asAddr() -> sockaddr {
        
        var temp = self
        let addr = withUnsafePointer(to: &temp) {
            return UnsafeRawPointer($0)
        }
        return addr.assumingMemoryBound(to: sockaddr.self).pointee
    }
    
}

public extension sockaddr_in6 {
    
    public func asAddr() -> sockaddr {
        
        var temp = self
        let addr = withUnsafePointer(to: &temp) {
            return UnsafeRawPointer($0)
        }
        return addr.assumingMemoryBound(to: sockaddr.self).pointee
    }
    
}

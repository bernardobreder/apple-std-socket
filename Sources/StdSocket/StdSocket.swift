//
//  StdSocketServer.swift
//  codegenv
//
//  Created by Bernardo Breder on 31/10/16.
//  Copyright © 2016 Bernardo Breder. All rights reserved.
//

import Foundation

#if os(macOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

open class StdSocket {
    
    public class func socket(port: Int, queueSize: Int) throws -> Int32 {
        guard let socket = StdSocket.socketCreate() else {
            throw StdSocketError.createServer
        }
        guard StdSocket.socketBind(socket, port: port) else {
            StdSocket.socketClose(socket)
            throw StdSocketError.bind
        }
        guard StdSocket.socketListen(socket, queue: queueSize) else {
            StdSocket.socketClose(socket)
            throw StdSocketError.listen
        }
        return socket
    }

    
    public class func socketCreate() -> Int32? {
        let fd: Int32
        #if os(Linux)
            fd = Glibc.socket(Int32(AF_INET), Int32(SOCK_STREAM.rawValue), Int32(IPPROTO_TCP))
        #else
            fd = Darwin.socket(Int32(AF_INET), Int32(SOCK_STREAM), Int32(IPPROTO_TCP))
        #endif
        guard fd >= 0 else { return nil }
        return fd
    }
    
    public class func socketBind(_ fd: Int32, port: Int) -> Bool {
        var sock_opt_on = Int32(1)
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &sock_opt_on, socklen_t(MemoryLayout.size(ofValue: sock_opt_on)))
        #if os(Linux)
            var addr: sockaddr = unsafeBitCast(sockaddr_in(sin_family: sa_family_t(AF_INET), sin_port: UInt16(port).bigEndian, sin_addr: in_addr(s_addr: in_addr_t(0)), sin_zero: (0,0,0,0,0,0,0,0)), to: sockaddr.self)
        #else
            var addr: sockaddr = unsafeBitCast(sockaddr_in(sin_len: 0, sin_family: sa_family_t(AF_INET), sin_port: UInt16(port).bigEndian, sin_addr: in_addr(s_addr: in_addr_t(0)), sin_zero: (0,0,0,0,0,0,0,0)), to: sockaddr.self)
        #endif
        guard bind(fd, &addr, socklen_t(MemoryLayout<sockaddr_in>.size)) != -1 else { return false }
        return true
    }
    
    public class func socketListen(_ fd: Int32, queue: Int) -> Bool {
        return listen(fd, Int32(queue)) >= 0
    }
    
    public class func socketAccept(_ fd: Int32) throws -> Int32 {
        var acceptAddr = sockaddr_in()
        var addrSize = socklen_t(MemoryLayout<sockaddr_in>.size)
        let cfd = accept(fd, UnsafeMutableRawPointer(&acceptAddr).assumingMemoryBound(to: sockaddr.self), &addrSize)
        guard cfd >= 0 else { throw StdSocketError.accept }
        return cfd
    }
    
    public class func receive(_ fd: Int32, count: Int) throws -> Data {
        var buffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer { buffer.deinitialize() }
        let readed: Int = recv(fd, buffer, count, 0)
        guard readed >= 0 else { throw StdSocketError.noData }
        guard count == readed else { throw StdSocketError.noAllDataAvaliable }
        var data: Data = Data.init(capacity: readed)
        data.append(buffer, count: readed)
        return data
    }
    
    public class func send(_ fd: Int32, data: Data) throws {
        let sended: Int
        #if os(Linux)
            sended = data.withUnsafeBytes({ Glibc.send(fd, $0, data.count, Int32(MSG_NOSIGNAL)) })
        #else
            sended = data.withUnsafeBytes({ Darwin.send(fd, $0, data.count, 0) })
        #endif
        guard sended == data.count else { throw StdSocketError.sendAllData }
    }
    
    public class func avaliable(_ fd: Int32) throws -> Int {
        var count: Int32 = 0
        let err: Int32
        #if os(Linux)
            err = ioctl(fd, UInt(Glibc.FIONREAD), &count)
        #else
            let FIONREAD : CUnsignedLong = ( 0x40000000 | ((CUnsignedLong(Int32(4)) & CUnsignedLong(IOCPARM_MASK)) << 16) | (102 << 8) | 127)
            err = ioctl(fd, FIONREAD, &count)
        #endif
        guard err == 0 else { throw StdSocketError.numberOfBytesAvaliable }
        return Int(count)
    }
    
    public class func waitAvaliable(_ fd: Int32, timeout: Int) throws -> Int {
        try StdSocket.wait(fd, timeout: timeout)
        let count = try StdSocket.avaliable(fd)
        guard count > 0 else { throw StdSocketError.noData }
        return count
    }

    public class func wait(_ fd: Int32, timeout: Int?) throws {
        var readfds = fd_set()
        StdSocketFileDescription.ZERO(set: &readfds)
        StdSocketFileDescription.SET(fd: fd, set: &readfds)
        if let timeout = timeout {
            var timeout = timeval(tv_sec: timeout, tv_usec: 0)
            let fd = select(fd + 1, &readfds, nil, nil, &timeout)
            if fd == 0 { throw StdSocketError.timeout }
            if fd < 0 { throw StdSocketError.wait }
        } else {
            let fd = select(fd + 1, &readfds, nil, nil, nil)
            if fd < 0 { throw StdSocketError.wait }
        }
    }

    public class func socketClose(_ fd: Int32) {
        _ = close(fd)
    }
    
}

public enum StdSocketError: Error {
    case createServer
    case bind
    case listen
    case accept
    case wait
    case noData
    case noAllDataAvaliable
    case sendAllData
    case numberOfBytesAvaliable
    case timeout
}

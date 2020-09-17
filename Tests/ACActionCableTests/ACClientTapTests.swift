//
//  ACClientTapTests.swift
//  ACActionCableTests
//
//  Created by Julian Tigler on 9/11/20.
//

import XCTest

class ACClientTapTests: XCTestCase {
    
    func testShouldCallOnConnected() throws {
        let expectedHeaders: ACRequestHeaders = [
            "Auth": "token",
            "Origin": "http://example.com",
        ]
        
        let socket = ACFakeWebSocket()
        let client = ACClient(socket: socket, headers: expectedHeaders)
        let semaphore = DispatchSemaphore(value: 0)
        let tap = ACClientTap(onConnected: { (headers) in
            XCTAssertEqual(expectedHeaders, headers)
            semaphore.signal()
        })
        client.add(tap)
        client.connect()
        
        let timeout: DispatchTime = .now() + .seconds(1)
        if semaphore.wait(timeout: timeout) == .timedOut { XCTFail() }
    }
    
    func testShouldCallOnDisconnected() throws {
        let expectedReason = "foo"
        
        let socket = ACFakeWebSocket(disconnectReason: expectedReason)
        let client = ACClient(socket: socket)
        let semaphore = DispatchSemaphore(value: 0)
        let tap = ACClientTap(onDisconnected: { (reason) in
            XCTAssertEqual(expectedReason, reason)
            semaphore.signal()
        })
        client.add(tap)
        client.connect()
        client.disconnect()
        
        let timeout: DispatchTime = .now() + .seconds(1)
        if semaphore.wait(timeout: timeout) == .timedOut { XCTFail() }
    }
}

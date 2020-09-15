//
//  File.swift
//  
//
//  Created by Julian Tigler on 9/11/20.
//

import XCTest

final class ACClientTests: XCTestCase {
        
    func testConnectShouldIncludeHeaders() throws {
        let semaphore = DispatchSemaphore(value: 0)

        let expectedHeaders: [String: String] = [
            "Auth": "token",
            "Origin": "http://example.com",
        ]
        
        let socket = ACFakeWebSocket(onConnect: { (headers) in
            XCTAssertEqual(expectedHeaders, headers)
            semaphore.signal()
        })
        
        let client = ACClient(ws: socket, headers: expectedHeaders)
        client.connect()
        
        let timeout: DispatchTime = .now() + .seconds(1)
        if semaphore.wait(timeout: timeout) == .timedOut { XCTFail() }
    }
    
    func testShouldNotStartConnectionMonitorWithNilTimeout() {
        let socket = ACFakeWebSocket()
        let client = ACClient(ws: socket, connectionMonitorTimeout: nil)
        client.connect()
        XCTAssertNil(client.connectionMonitor)
    }
    
    func testShouldStartConnectionMonitorWithTimeout() {
        let expected = 6.0
        let socket = ACFakeWebSocket()
        let client = ACClient(ws: socket, connectionMonitorTimeout: expected)
        client.connect()
        XCTAssertNotNil(client.connectionMonitor)
        XCTAssertEqual(expected, client.connectionMonitor!.staleThreshold)
        socket.onConnected?(nil)
        XCTAssert(client.connectionMonitor!.isRunning)
    }
}

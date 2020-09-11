//
//  File.swift
//  
//
//  Created by Julian Tigler on 9/11/20.
//

import XCTest
@testable import ActionCableSwift

final class ACClientTests: XCTestCase {
    
    private let halfSecondTimeout = DispatchTime(uptimeNanoseconds: 500_000_000)
    
    func testConnectShouldIncludeHeaders() {
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
        
        let result = semaphore.wait(timeout: halfSecondTimeout)
        XCTAssertEqual(.success, result)
    }
}

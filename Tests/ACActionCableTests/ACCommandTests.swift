//
//  ACCommandTests.swift
//  ACActionCableTests
//
//  Created by Julian Tigler on 9/14/20.
//

import XCTest

class ACCommandTests: XCTestCase {
    
    func testShouldEncodeSubscribe() throws {
        let expected = #"{"command":"subscribe","identifier":"{\"channel\":\"TestChannel\",\"test_id\":42}"}"#
        let identifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 42])!
        let command = ACCommand(type: .subscribe, identifier: identifier)
        XCTAssertEqual(expected, command?.string)
    }
    
    func testShouldEncodeUnsubscribe() throws {
        let expected = #"{"command":"unsubscribe","identifier":"{\"channel\":\"TestChannel\",\"test_id\":42}"}"#
        let identifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 42])!
        let command = ACCommand(type: .unsubscribe, identifier: identifier)
        XCTAssertEqual(expected, command?.string)
    }
    
    func testShouldEncodeMessage() throws {
        let expected = #"{"command":"message","data":"{\"action\":\"foo\",\"bar\":1}","identifier":"{\"channel\":\"TestChannel\",\"test_id\":42}"}"#
        let identifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 42])!
        let command = ACCommand(type: .message, identifier: identifier, action: "foo", data: ["bar": 1])
        XCTAssertEqual(expected, command?.string)
    }
}

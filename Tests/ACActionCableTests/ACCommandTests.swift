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
        struct MyObject: Encodable {
            let myInt: Int
            let myString: String
        }
        
        let expected = #"{"command":"message","data":"{\"action\":\"my_action\",\"my_object\":{\"my_int\":1,\"my_string\":\"test\"}}","identifier":"{\"channel\":\"TestChannel\",\"test_id\":42}"}"#
        let identifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 42])!
        let command = ACCommand(type: .message, identifier: identifier, action: "my_action", object: MyObject(myInt: 1, myString: "test"))
        XCTAssertEqual(expected, command?.string)
    }
}

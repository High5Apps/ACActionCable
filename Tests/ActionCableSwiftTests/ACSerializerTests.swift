//
//  ACSerializerTests.swift
//  ActionCableSwiftTests
//
//  Created by Julian Tigler on 9/11/20.
//

import XCTest

class ACSerializerTests: XCTestCase {

    func testShouldDesrializeWelcome() throws {
        let welcomeMessage = #"{"type":"welcome"}"#
        let message = ACSerializer.responseFrom(stringData: welcomeMessage)
        XCTAssertEqual(.welcome, message.type)
    }
    
    func testShouldDesrializePing() throws {
        let welcomeMessage = #"{"type":"ping","message":1599874600}"#
        let message = ACSerializer.responseFrom(stringData: welcomeMessage)
        XCTAssertEqual(.ping, message.type)
    }
    
    func testShouldDesrializeConfirmationSubscription() throws {
        let confirmation = #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","type":"confirm_subscription"}"#
        let message = ACSerializer.responseFrom(stringData: confirmation)
        XCTAssertEqual(.confirmSubscription, message.type)
        
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])
        XCTAssertEqual(channelIdentifier, message.identifier)
    }
    
    func testShouldDesrializeConfirmationRejection() throws {
        let rejection = #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","type":"reject_subscription"}"#
        let message = ACSerializer.responseFrom(stringData: rejection)
        XCTAssertEqual(.rejectSubscription, message.type)
        
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])
        XCTAssertEqual(channelIdentifier, message.identifier)        
    }
}

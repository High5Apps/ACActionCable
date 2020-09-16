//
//  ACMessageTests.swift
//  ACActionCableTests
//
//  Created by Julian Tigler on 9/12/20.
//

import XCTest

class ACMessageTests: XCTestCase {
    
    func testShouldDecodeWelcome() throws {
        let string = #"{"type":"welcome"}"#
        let message = ACMessage(string: string)!
        XCTAssertEqual(.welcome, message.type)
    }
    
    func testShouldDecodePing() throws {
        let timeInterval: Int = 1599874600
        let string = "{\"type\":\"ping\",\"message\":\(timeInterval)}"
        let message = ACMessage(string: string)!
        XCTAssertEqual(.ping, message.type)

        switch message.body {
        case .ping(let value):
            XCTAssertEqual(timeInterval, value)
        default:
            XCTFail()
        }
    }
    
    func testShouldDecodeCustomMessage() throws {
        struct Foo: Decodable {
            let bar: Int
            let zap: String
        }
        
        struct BarBaz: Decodable {
            let bimBam: String
        }
        
        ACMessageBodyObject.register(Foo.self)
        ACMessageBodyObject.register(BarBaz.self)
        
        [
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"bar_baz":{"bim_bam":"moz"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"foo":{"bar":1,"zap":"bam"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"bar_baz":{"bim_bam":"moz"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"foo":{"bar":1,"zap":"bam"}}}"#,
        ].forEach { (string) in
            let message = ACMessage(string: string)!
            XCTAssertNil(message.type)
            switch message.body {
            case .dictionary(let bodyObject):
                switch bodyObject.object {
                case let foo as Foo:
                    XCTAssertEqual(1, foo.bar)
                    XCTAssertEqual("bam", foo.zap)
                case let bar as BarBaz:
                    XCTAssertEqual("moz", bar.bimBam)
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
            
            let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])
            XCTAssertEqual(channelIdentifier, message.identifier)
        }
    }
    
    func testShouldDecodeConfirmationSubscription() throws {
        let string = #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","type":"confirm_subscription"}"#
        let message = ACMessage(string: string)!
        XCTAssertEqual(.confirmSubscription, message.type)
        
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])
        XCTAssertEqual(channelIdentifier, message.identifier)
    }
    
    func testShouldDecodeConfirmationRejection() throws {
        let string = #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","type":"reject_subscription"}"#
        let message = ACMessage(string: string)!
        XCTAssertEqual(.rejectSubscription, message.type)
        
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])
        XCTAssertEqual(channelIdentifier, message.identifier)
    }
    
    func testShouldDecodeDisconnect() throws {
        let string = #"{"type":"disconnect","reason":"unauthorized","reconnect":false}"#
        let message = ACMessage(string: string)!
        XCTAssertEqual(.disconnect, message.type)
        XCTAssertEqual(.unauthorized, message.disconnectReason)
        XCTAssertEqual(false, message.reconnect)
    }
}

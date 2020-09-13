//
//  ACDecodableMessageTests.swift
//  ActionCableSwiftTests
//
//  Created by Julian Tigler on 9/12/20.
//

import XCTest

class ACDecodableMessageTests: XCTestCase {
    
    private let decoder = JSONDecoder()
    
    func testShouldDecodeWelcome() throws {
        let string = #"{"type":"welcome"}"#
        let message = try! decoder.decode(ACDecodableMessage.self, from: string.data(using: .utf8)!)
        XCTAssertEqual(.welcome, message.type)
    }
    
    func testShouldDesrializePing() throws {
        let string = #"{"type":"ping","message":1599874600}"#
        let message = try! decoder.decode(ACDecodableMessage.self, from: string.data(using: .utf8)!)
        XCTAssertEqual(.ping, message.type)

        switch message.body {
        case .int(let value):
            XCTAssertEqual(1599874600, value)
        default:
            XCTFail()
        }
    }
    
    func testShouldDesrializeMessage() throws {
        struct Foo: Decodable {
            let bar: Int
            let zap: String
        }
        
        struct Bar: Decodable {
            let bim: String
        }
        
        BodyObject.register(Foo.self, for: "Foo")
        BodyObject.register(Bar.self, for: "Bar")
        let decoder = JSONDecoder()
        
        [
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"Bar":{"bim":"moz"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"Foo":{"bar":1,"zap":"bam"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"Bar":{"bim":"moz"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"Foo":{"bar":1,"zap":"bam"}}}"#,
        ].forEach { (string) in
            let message = try! decoder.decode(ACDecodableMessage.self, from: string.data(using: .utf8)!)
            XCTAssertNil(message.type)
            switch message.body {
            case .dictionary(let bodyObject):
                switch bodyObject.object {
                case let foo as Foo:
                    XCTAssertEqual(1, foo.bar)
                    XCTAssertEqual("bam", foo.zap)
                case let bar as Bar:
                    XCTAssertEqual("moz", bar.bim)
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
        let message = try! decoder.decode(ACDecodableMessage.self, from: string.data(using: .utf8)!)
        XCTAssertEqual(.confirmSubscription, message.type)
        
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])
        XCTAssertEqual(channelIdentifier, message.identifier)
    }
    
    func testShouldDecodeConfirmationRejection() throws {
        let string = #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","type":"reject_subscription"}"#
        let message = try! decoder.decode(ACDecodableMessage.self, from: string.data(using: .utf8)!)
        XCTAssertEqual(.rejectSubscription, message.type)
        
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])
        XCTAssertEqual(channelIdentifier, message.identifier)
    }
}

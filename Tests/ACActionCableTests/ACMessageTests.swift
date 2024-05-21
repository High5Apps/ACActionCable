//
//  ACMessageTests.swift
//  ACActionCableTests
//
//  Created by Julian Tigler on 9/12/20.
//

import XCTest

class ACMessageTests: XCTestCase {

    override func setUp() async throws {
        ACMessage.unregisterAllTypes()
    }

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
    
    func testShouldDecodeCustomMessageWithSingleObject() throws {
        struct Foo: Decodable {
            let bar: Int
            let zap: String
        }
        
        struct BarBaz: Decodable {
            let bimBam: String
        }
        
        ACMessageBodySingleObject.register(type: Foo.self)
        ACMessageBodySingleObject.register(type: BarBaz.self)

        [
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"bar_baz":{"bim_bam":"moz"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"foo":{"bar":1,"zap":"bam"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"bar_baz":{"bim_bam":"moz"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"foo":{"bar":1,"zap":"bam"}}}"#,
        ].forEach { (string) in
            let message = ACMessage(string: string)!
            XCTAssertNil(message.type)
            switch message.body {
            case .object(let bodyObject):
                switch bodyObject {
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

    func testShouldDecodeCustomMessage() throws {
        struct Foo: Decodable {
            let bar: Int
            let zap: String
        }

        struct BarBaz: Decodable {
            let bimBam: String
        }

        struct MessageType: Decodable {
            let foo: Foo?
            let barBaz: BarBaz?
        }

        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])!
        ACMessage.register(type: MessageType.self, forChannelIdentifier: channelIdentifier)

        [
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"bar_baz":{"bim_bam":"moz"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"foo":{"bar":1,"zap":"bam"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"bar_baz":{"bim_bam":"moz"}}}"#,
            #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"foo":{"bar":1,"zap":"bam"}}}"#,
        ].forEach { (string) in
            let message = ACMessage(string: string)!
            XCTAssertNil(message.type)
            switch message.body {
            case .object(let bodyObject):
                guard let message = bodyObject as? MessageType else {
                    XCTFail()
                    return;
                }

                if let foo = message.foo {
                    XCTAssertEqual(1, foo.bar)
                    XCTAssertEqual("bam", foo.zap)
                } else if let bar = message.barBaz {
                    XCTAssertEqual("moz", bar.bimBam)
                } else {
                    XCTFail()
                }
            default:
                XCTFail()
            }

            let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])
            XCTAssertEqual(channelIdentifier, message.identifier)
        }
    }

    func testShoulDecodeDateUsingSecondsSince1970() throws {
        struct MyDate: Decodable {
            let date: Date
        }
        ACMessageBodySingleObject.register(type: MyDate.self)

        let expected = Date()
        let format = #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"my_date":{"date":%f}}}"#
        let string = String(format: format, expected.timeIntervalSince1970)
        
        ACMessage.decoder.dateDecodingStrategy = .secondsSince1970
        let message = ACMessage(string: string)

        switch message?.body {
        case .object(let bodyObject):
            switch bodyObject {
            case let myDate as MyDate:
                XCTAssertEqual(expected.timeIntervalSince1970, myDate.date.timeIntervalSince1970, accuracy: 1e-3)
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }
    
    func testShoulDecodeDateUsingDecoderDateStrategy() throws {
        struct MyDate: Decodable {
            let date: Date
        }
        ACMessageBodySingleObject.register(type: MyDate.self)

        let expected = Date()
        let format = #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","message":{"my_date":{"date":%@}}}"#
        let string = String(format: format, ISO8601DateFormatter().string(from: expected).debugDescription)
        
        ACMessage.decoder.dateDecodingStrategy = .iso8601
        let message = ACMessage(string: string)
        ACMessage.decoder.dateDecodingStrategy = .secondsSince1970

        switch message?.body {
        case .object(let bodyObject):
            switch bodyObject {
            case let myDate as MyDate:
                // Note that .iso8601 does not allow fractional seconds
                XCTAssertEqual(floor(expected.timeIntervalSince1970), myDate.date.timeIntervalSince1970)
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }
    
    func testShouldDecodeConfirmSubscription() throws {
        let string = #"{"identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}","type":"confirm_subscription"}"#
        let message = ACMessage(string: string)!
        XCTAssertEqual(.confirmSubscription, message.type)
        
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])
        XCTAssertEqual(channelIdentifier, message.identifier)
    }
    
    func testShouldDecodeRejectSubscription() throws {
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

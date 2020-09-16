//
//  ACClientTests.swift
//  ACActionCableTests
//
//  Created by Julian Tigler on 9/11/20.
//

import XCTest

final class ACClientTests: XCTestCase {
    
    // MARK: Connections
    
    func testConnectShouldIncludeHeaders() throws {
        let semaphore = DispatchSemaphore(value: 0)

        let expectedHeaders: ACRequestHeaders = [
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
    
    // MARK: Connection monitoring
    
    func testShouldNotStartConnectionMonitorWithNilTimeout() throws {
        let socket = ACFakeWebSocket()
        let client = ACClient(ws: socket, connectionMonitorTimeout: nil)
        client.connect()
        XCTAssertNil(client.connectionMonitor)
    }
    
    func testShouldStartConnectionMonitorWithTimeout() throws {
        let expected = 6.0
        let socket = ACFakeWebSocket()
        let client = ACClient(ws: socket, connectionMonitorTimeout: expected)
        client.connect()
        XCTAssertNotNil(client.connectionMonitor)
        XCTAssertEqual(expected, client.connectionMonitor!.staleThreshold)
        socket.onConnected?(nil)
        XCTAssert(client.connectionMonitor!.isRunning)
    }
    
    // MARK: Subscriptions
    
    func testShouldSubscribeAndUnsubscribe() throws {
        let expectedSubscribe = #"{"command":"subscribe","identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}"}"#
        let expectedUnsubscribe = #"{"command":"unsubscribe","identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}"}"#
        let subscribe = expectation(description: "Subscribe")
        let unsubscribe = expectation(description: "Unsubscribe")
        let socket = ACFakeWebSocket(onSendText: { (text) in
            if text == expectedSubscribe {
                subscribe.fulfill()
            } else if text == expectedUnsubscribe {
                unsubscribe.fulfill()
            }
        })
        let client = ACClient(ws: socket)
        client.connect()
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])!
        let subscription = client.subscribe(to: channelIdentifier, with:  { (_) in })!
        wait(for: [subscribe], timeout: 1)
        client.unsubscribe(from: subscription)
        wait(for: [unsubscribe], timeout: 1)
    }
    
    func testSubscribeShouldNoOpWhenAlreadySubscribed() throws {
        let socket = ACFakeWebSocket()
        let client = ACClient(ws: socket)
        client.connect()
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])!
        let subscription = client.subscribe(to: channelIdentifier, with: { (_) in })
        XCTAssertNotNil(subscription)
        let nilSubscription = client.subscribe(to: channelIdentifier, with: { (_) in })
        XCTAssertNil(nilSubscription)
    }
    
    func testUnsubscribeShouldNoOpWhenNotSubscribed() throws {
        let socket = ACFakeWebSocket()
        let client = ACClient(ws: socket)
        client.connect()
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])!
        let subscription = client.subscribe(to: channelIdentifier, with: { (_) in })!
        var unsubscribed = client.unsubscribe(from: subscription)
        XCTAssert(unsubscribed)
        unsubscribed = client.unsubscribe(from: subscription)
        XCTAssertFalse(unsubscribed)
    }
    
    func testShouldOnlyNotifyTheIdentifiedSubscriber() throws {
        let socket = ACFakeWebSocket()
        let client = ACClient(ws: socket)
        client.connect()
        
        for i in 0..<3 {
            let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": i])!
            let subscribe = expectation(description: "Subscribe\(i)")
            let _ = client.subscribe(to: channelIdentifier, with: { (message) in
                switch message.type {
                case .confirmSubscription:
                    subscribe.fulfill()
                default:
                    break
                }
            })!
            socket.confirmSubscription(to: channelIdentifier)
            wait(for: [subscribe], timeout: 1)
        }
    }
    
    func testShouldNotNotifyOnceUnsubscribed() throws {
        let socket = ACFakeWebSocket()
        let client = ACClient(ws: socket)
        client.connect()
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 1])!
        let subscribe = expectation(description: "Subscribe")
        let subscription = client.subscribe(to: channelIdentifier, with: { (message) in
            switch message.type {
            case .confirmSubscription:
                subscribe.fulfill()
            default:
                break
            }
        })!
        socket.confirmSubscription(to: channelIdentifier)
        wait(for: [subscribe], timeout: 1)
        client.unsubscribe(from: subscription)
        socket.confirmSubscription(to: channelIdentifier)
    }
}

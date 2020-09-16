//
//  ACSubscriptionTests.swift
//  ACActionCableTests
//
//  Created by Julian Tigler on 9/16/20.
//

import XCTest

class ACSubscriptionTests: XCTestCase {

    func testShouldSend() throws {
        let expectedSend = #"{"command":"message","data":"{\"action\":\"speak\"}","identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}"}"#
        let (subscription, expectation) = expectMessage(expectedSend)
        subscription.send(actionName: "speak")
        wait(for: [expectation], timeout: 1)
    }
    
    func testShouldSendWithData() throws {
        let expectedSend = #"{"command":"message","data":"{\"action\":\"speak\",\"bar\":1}","identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}"}"#
        let (subscription, expectation) = expectMessage(expectedSend)
        subscription.send(actionName: "speak", data: ["bar": 1])
        wait(for: [expectation], timeout: 1)
    }
    
    private func expectMessage(_ expectedSend: String) -> (ACSubscription, XCTestExpectation) {
        let expectedSubscribe = #"{"command":"subscribe","identifier":"{\"channel\":\"TestChannel\",\"test_id\":32}"}"#
        let subscribe = expectation(description: "Subscribe")
        let send = expectation(description: "Send")
        let socket = ACFakeWebSocket(onSendText: { (text) in
            if text == expectedSubscribe {
                subscribe.fulfill()
            } else if text == expectedSend {
                send.fulfill()
            }
        })
        let client = ACClient(ws: socket)
        client.connect()
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: ["test_id": 32])!
        let subscription = client.subscribe(to: channelIdentifier, with: { (_) in })!
        wait(for: [subscribe], timeout: 1)
        return(subscription, send)
    }
}

//
//  ACChannelIdentifierTests.swift
//  ActionCableSwiftTests
//
//  Created by Julian Tigler on 9/11/20.
//

import XCTest

class ACChannelIdentifierTests: XCTestCase {

    func testShouldSortKeysInString() throws {
        let channelIdentifier = ACChannelIdentifier(channelName: "TestChannel", identifier: [
            "baz_id": 5,
            "foo_id": 5,
            "bar_id": 5,
        ])!
        let expected = #"{"bar_id":5,"baz_id":5,"channel":"TestChannel","foo_id":5}"#
        XCTAssertEqual(expected, channelIdentifier.string)
    }
}

//
//  ACConnectionMonitorTests.swift
//  ACActionCableTests
//
//  Created by Julian Tigler on 9/14/20.
//

import XCTest

class ACConnectionMonitorTests: XCTestCase {
    
    private var socket: ACFakeWebSocket!
    private var monitor: ACConnectionMontior!
    
    override func setUp() {
        socket = ACFakeWebSocket()
        let client = ACClient(ws: socket)
        monitor = ACConnectionMontior(client: client, staleThreshold: 6)
        ACConnectionMontior.now = { Date() }
        ACConnectionMontior.pollIntervalRange = 3..<30
        ACConnectionMontior.reconnectDelay = 0
    }
    
    func testStartStop() {
        for _ in 0..<2 {
            monitor.start()
            XCTAssert(monitor.isRunning)
            monitor.stop()
            XCTAssert(!monitor.isRunning)
        }
    }
    
    func testStartShouldNoOpIfAlreadyStarted() throws {
        monitor.start()
        let startedAt = monitor.startedAt
        monitor.start()
        XCTAssertEqual(startedAt, monitor.startedAt)
    }
    
    func testStopShouldNoOpIfAlreadyStopped() throws {
        monitor.start()
        monitor.stop()
        let stoppedAt = monitor.stoppedAt
        monitor.stop()
        XCTAssertEqual(stoppedAt, monitor.stoppedAt)
    }
    
    func testShouldStartOnClientConnected() throws {
        XCTAssert(!monitor.isRunning)
        socket.onConnected?(nil)
        XCTAssert(monitor.isRunning)
    }
    
    func testShouldRecordPingOnActionCablePingNotWebSocketPing() throws {
        monitor.start()
        XCTAssertNil(monitor.pingedAt)
        socket.onConnected?(nil)
        let pingedAt = monitor.pingedAt
        XCTAssertNotNil(pingedAt)
        socket.onPing?()
        XCTAssertEqual(pingedAt!, monitor.pingedAt)
        ping()
        XCTAssert(monitor.pingedAt! > pingedAt!)
    }
    
    func testIsConnectionStale() throws {
        XCTAssert(!monitor.isConnectionStale)
        monitor.start()
        XCTAssert(!monitor.isConnectionStale)
        ACConnectionMontior.now = { self.monitor.startedAt! + self.monitor.staleThreshold - 0.01 }
        XCTAssert(!monitor.isConnectionStale)
        ACConnectionMontior.now = { self.monitor.startedAt! + self.monitor.staleThreshold }
        XCTAssert(monitor.isConnectionStale)
        ping()
        XCTAssert(!monitor.isConnectionStale)
        ACConnectionMontior.now = { self.monitor.pingedAt! + self.monitor.staleThreshold - 0.01 }
        XCTAssert(!monitor.isConnectionStale)
        ACConnectionMontior.now = { self.monitor.pingedAt! + self.monitor.staleThreshold }
        XCTAssert(monitor.isConnectionStale)
    }
    
    func testDisconnectedRecently() throws {
        XCTAssert(!monitor.disconnectedRecently)
        monitor.start()
        socket.onDisconnected?(nil)
        XCTAssertNotNil(monitor.disconnectedAt)
        XCTAssert(monitor.disconnectedRecently)
        ACConnectionMontior.now = { self.monitor.disconnectedAt! + self.monitor.staleThreshold - 0.01 }
        XCTAssert(monitor.disconnectedRecently)
        ACConnectionMontior.now = { self.monitor.disconnectedAt! + self.monitor.staleThreshold }
        XCTAssert(!monitor.disconnectedRecently)
    }
    
    func testPollIntervalShouldIncreaseWithReconnectAttempts() throws {
        let range: Range<UInt32> = 3..<6
        ACConnectionMontior.pollIntervalRange = range
        var lastInterval: UInt32 = 0
        for i in 0..<15 {
            monitor.reconnectAttempts += 1
            let interval = monitor.pollInterval
            switch i {
            case 0:
                XCTAssertEqual(range.lowerBound, monitor.pollInterval)
            case 14:
                XCTAssertEqual(range.upperBound, monitor.pollInterval)
            default:
                XCTAssert(interval >= lastInterval)
            }
            lastInterval = interval
        }
    }
    
    func testReconnectIfStale() throws {
        socket.onConnect = nil

        monitor.start()
        socket.onConnected?(nil)
        ACConnectionMontior.now = { self.monitor.pingedAt! + self.monitor.staleThreshold - 0.01 }
        monitor.reconnectIfStale()
        XCTAssertEqual(0, monitor.reconnectAttempts)
        ACConnectionMontior.now = { self.monitor.pingedAt! + self.monitor.staleThreshold }
        monitor.reconnectIfStale()
        XCTAssertEqual(1, monitor.reconnectAttempts)
        socket.onConnected?(nil)
        XCTAssertEqual(0, monitor.reconnectAttempts)
        ACConnectionMontior.now = { self.monitor.pingedAt! + self.monitor.staleThreshold }
        XCTAssert(monitor.isConnectionStale)
        socket.onDisconnected?(nil)
        XCTAssert(monitor.disconnectedRecently)
        monitor.reconnectIfStale()
        XCTAssertEqual(0, monitor.reconnectAttempts)
        ACConnectionMontior.now = { self.monitor.disconnectedAt! + self.monitor.staleThreshold }
        monitor.reconnectIfStale()
        XCTAssertEqual(1, monitor.reconnectAttempts)
    }
    
    func testShouldStopIfReconnectFalse() throws {
        monitor.start()
        XCTAssert(monitor.isRunning)
        let shouldReconnect = #"{"type":"disconnect","reason":"unauthorized","reconnect":true}"#
        socket.onText?(shouldReconnect)
        XCTAssert(monitor.isRunning)
        socket.onDisconnected?(nil)
        XCTAssert(monitor.isRunning)
        let shouldNotReconnect = #"{"type":"disconnect","reason":"unauthorized","reconnect":false}"#
        socket.onText?(shouldNotReconnect)
        XCTAssert(!monitor.isRunning)
    }
    
    private func ping() {
        let text = "{\"type\":\"ping\",\"message\":\(ACConnectionMontior.now().timeIntervalSince1970)}"
        socket.onText?(text)
    }
}

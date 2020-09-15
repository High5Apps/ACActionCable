//
//  ACConnectionMontior.swift
//  
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation
import SwiftExtensionsPack
import os.log

public final class ACConnectionMontior {
    
    // MARK: Properties
    
    static var now: () -> Date = { Date() }
    static var pollIntervalRange: Range<UInt32> = 3..<30
    static var pollIntervalMultiplier = 5.0
    static var reconnectDelay: UInt32 = 1
    
    var startedAt: Date?
    var stoppedAt: Date?
    var pingedAt: Date?
    var disconnectedAt: Date?
    var reconnectAttempts = 0
    
    var isConnectionStale: Bool {
        guard let startedAt = startedAt else { return false }
        let lastEvent = pingedAt ?? startedAt
        return Self.now() >= lastEvent + staleThreshold
    }
    
    var isRunning: Bool {
        (startedAt != nil) && (stoppedAt == nil)
    }
    
    var disconnectedRecently: Bool {
        guard let disconnectedAt = disconnectedAt else { return false }
        return Self.now() < disconnectedAt + staleThreshold
    }
    
    var pollInterval: UInt32 {
        let interval = UInt32(Self.pollIntervalMultiplier * log(Double(1 + reconnectAttempts)))
        guard interval > Self.pollIntervalRange.lowerBound else { return Self.pollIntervalRange.lowerBound }
        guard interval < Self.pollIntervalRange.upperBound else { return Self.pollIntervalRange.upperBound }
        return interval
    }
        
    let staleThreshold: TimeInterval
    
    private weak var client: ACClient?
    
    // MARK: Initialization
    
    init(client: ACClient, staleThreshold: TimeInterval) {
        self.client = client
        self.staleThreshold = staleThreshold
        self.client?.add(ACClientTap(onConnected: onConnected(_:), onDisconnected: onDisconnected(_:), onMessage: onMessage(_:)))
    }
    
    // MARK: Starting and stopping
    
    func start() {
        guard !isRunning else { return }
        startedAt = Self.now()
        stoppedAt = nil
        
        startPolling()
    }
    
    private func startPolling() {
        Thread() {
            while self.stoppedAt == nil {
                sleep(self.pollInterval)
                self.reconnectIfStale()
            }
        }.start()
    }
    
    func reconnectIfStale() {
        guard isConnectionStale && !disconnectedRecently else { return }
        reconnectAttempts += 1
        client?.disconnect()
        sleep(Self.reconnectDelay)
        client?.connect()
    }
    
    func stop() {
        guard isRunning else { return }
        stoppedAt = Self.now()
    }
    
    private func recordPing() {
        pingedAt = Self.now()
    }
    
    // MARK: Tap Callbacks
    
    private func onConnected(_ headers: [String: String]?) {
        reconnectAttempts = 0
        recordPing()
        disconnectedAt = nil
        start()
    }
    
    private func onDisconnected(_ reason: String?) {
        disconnectedAt = Self.now()
    }
    
    private func onMessage(_ message: ACMessage) {
        switch message.type {
        case .ping:
            recordPing()
        case .disconnect:
            if let reconnect = message.reconnect, !reconnect {
                stop()
            }
        default:
            break
        }
    }
}

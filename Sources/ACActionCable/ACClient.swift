//
//  ACClient.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public final class ACClient {
    
    // MARK: Properties
    
    public var headers: ACRequestHeaders? = nil
    
    static var reconnectDelay: UInt32 = 1
    
    var connectionMonitor: ACConnectionMontior?
    
    private var socket: ACWebSocketProtocol
    private var subscriptions: [ACChannelIdentifier: ACSubscription] = [:]
    private var taps: Set<ACClientTap> = []
    
    // MARK: Initialization
    
    public init(socket: ACWebSocketProtocol, headers: ACRequestHeaders? = nil, connectionMonitorTimeout: TimeInterval? = nil) {
        self.socket = socket
        self.socket.onConnected = onSocketConnected(headers:)
        self.socket.onDisconnected = onSocketDisconnected(reason:)
        self.socket.onText = onSocketText(text:)
        
        self.headers = headers
        
        if let timeout = connectionMonitorTimeout {
            connectionMonitor = ACConnectionMontior(client: self, staleThreshold: timeout)
        }
    }
    
    // MARK: Socket Callbacks
    
    private func onSocketConnected(headers: ACRequestHeaders?) {
        taps.forEach() { $0.onConnected?(headers) }
        
        subscriptions.keys.forEach() {
            guard let command = ACCommand(type: .subscribe, identifier: $0) else { return }
            send(command)
        }
    }
    
    private func onSocketDisconnected(reason: String?) {
        taps.forEach() { $0.onDisconnected?(reason) }
    }
    
    private func onSocketText(text: String) {
        taps.forEach() { $0.onText?(text) }
        
        guard let message = ACMessage(string: text) else { return }
        
        taps.forEach() { $0.onMessage?(message) }
        
        guard let channelIdentifier = message.identifier, let subscription = subscriptions[channelIdentifier] else { return }

        subscription.onMessage(message)
        
        switch message.type {
        case .rejectSubscription:
            self.subscriptions.removeValue(forKey: subscription.channelIdentifier)
        default:
            break
        }
    }
    
    // MARK: Connections
    
    public func connect() {
        connectionMonitor?.start()
        socket.connect(headers: headers)
    }
    
    public func disconnect(allowReconnect: Bool = false) {
        if !allowReconnect {
            connectionMonitor?.stop()
        }
        
        socket.disconnect()
    }
    
    func reconnect() {
        socket.disconnect()
        sleep(Self.reconnectDelay)
        socket.connect(headers: headers)
    }
    
    // MARK: Sending
    
    func send(_ command: ACCommand, completion: ACEventHandler? = nil) {
        guard let text = command.string else { return }
        socket.send(text: text, completion: completion)
    }
    
    // MARK: Subscriptions
    
    public func subscribe(to channelIdentifier: ACChannelIdentifier, with messageHandler: @escaping ACMessageHandler) -> ACSubscription? {
        guard let command = ACCommand(type: .subscribe, identifier: channelIdentifier) else { return nil }
        
        let subscription = ACSubscription(client: self, channelIdentifier: channelIdentifier, onMessage: messageHandler)
        
        guard subscriptions[subscription.channelIdentifier] == nil else { return nil }

        subscriptions[subscription.channelIdentifier] = subscription
        send(command)
        
        return subscription
    }
    
    @discardableResult
    public func unsubscribe(from subscription: ACSubscription) -> Bool {
        guard subscriptions[subscription.channelIdentifier] != nil else { return false }
        
        guard let command = ACCommand(type: .unsubscribe, identifier: subscription.channelIdentifier) else { return false }
        
        subscriptions.removeValue(forKey: subscription.channelIdentifier)
        send(command)
        
        return true
    }
    
    // MARK: Tapping
    
    public func add(_ tap: ACClientTap) {
        taps.insert(tap)
    }
    
    public func remove(_ tap: ACClientTap) {
        taps.remove(tap)
    }
    
    // MARK: Deinitialization
    
    deinit {
        connectionMonitor?.stop()
    }
}

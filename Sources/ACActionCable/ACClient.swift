//
//  ACClient.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public typealias ACRequestHeaders = [String: String]
public typealias ACConnectionHandler = (_ headers: ACRequestHeaders?) -> Void
public typealias ACDisconnectionHandler = (_ reason: String?) -> Void
public typealias ACEventHandler = () -> Void
public typealias ACTextHandler = (_ text: String) -> Void
public typealias ACMessageHandler = (ACMessage) -> Void

public final class ACClient {
    
    // MARK: Properties
    
    public var headers: ACRequestHeaders? = nil
    
    var connectionMonitor: ACConnectionMontior?
    
    private var socket: ACWebSocketProtocol
    private var subscriptions: [ACChannelIdentifier: ACSubscription] = [:]
    private var taps: Set<ACClientTap> = []
    
    // MARK: Initialization
    
    public init(ws: ACWebSocketProtocol, headers: ACRequestHeaders? = nil, connectionMonitorTimeout: TimeInterval? = nil) {
        self.socket = ws
        self.headers = headers
        setupWSCallbacks()
        if let timeout = connectionMonitorTimeout {
            connectionMonitor = ACConnectionMontior(client: self, staleThreshold: timeout)
        }
    }
    
    private func setupWSCallbacks() {
        socket.onConnected = { (headers) in
            self.taps.forEach() { $0.onConnected?(headers) }
        }
        
        socket.onDisconnected = { (reason) in
            self.taps.forEach() { $0.onDisconnected?(reason) }
        }
        
        socket.onText = { (text) in
            self.taps.forEach() { $0.onText?(text) }
            
            guard let message = ACMessage(string: text) else { return }
            
            self.taps.forEach() { $0.onMessage?(message) }
            
            guard let channelIdentifier = message.identifier, let subscription = self.subscriptions[channelIdentifier] else { return }

            subscription.onMessage(message)
        }
    }
    
    // MARK: Connections
    
    public func connect() {
        socket.connect(headers: headers)
    }
    
    public func disconnect(allowReconnect: Bool = true) {
        if !allowReconnect {
            connectionMonitor?.stop()
        }
        
        socket.disconnect()
    }
    
    // MARK: Sending
    
    func send(_ command: ACCommand, completion: ACEventHandler? = nil) {
        guard let text = command.string else { return }
        socket.send(text: text, completion)
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

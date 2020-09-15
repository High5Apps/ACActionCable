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
public typealias ACDataHandler = (_ data: Data) -> Void

public final class ACClient {
    
    // MARK: Properties
    
    public var headers: ACRequestHeaders? = nil
    
    var isConnected: Bool = false
    var connectionMonitor: ACConnectionMontior?

    private var socket: ACWebSocketProtocol
    private var subscriptions: Set<ACSubscription> = []
    private var taps: Set<ACClientTap> = []
    
    private let isConnectedLock: NSLock = .init()
    private let sendLock: NSLock = .init()
    
    // MARK: Initialization

    public init(ws: ACWebSocketProtocol, headers: ACRequestHeaders? = nil, connectionMonitorTimeout: TimeInterval? = nil) {
        self.socket = ws
        self.headers = headers
        setupWSCallbacks()
        if let timeout = connectionMonitorTimeout {
            connectionMonitor = ACConnectionMontior(client: self, staleThreshold: timeout)
        }
    }
    
    // MARK: Connection management

    public func connect() {
        isConnectedLock.lock()
        socket.connect(headers: headers)
        isConnectedLock.unlock()
    }

    public func disconnect(allowReconnect: Bool = true) {
        if !allowReconnect {
            connectionMonitor?.stop()
        }
        
        isConnectedLock.lock()
        socket.disconnect()
        isConnectedLock.unlock()
    }
    
    // MARK: Sending messages

    public func send(text: String, _ completion: ACEventHandler? = nil) {
        sendLock.lock()
        socket.send(text: text) {
            completion?()
        }
        sendLock.unlock()
    }
    
    // MARK: Subscriptions
    
    public func subscribe(to channelIdentifier: ACChannelIdentifier, with messageHandler: @escaping ACMessageHandler) -> ACSubscription? {
        guard let command = ACCommand(type: .subscribe, identifier: channelIdentifier), let subscribe = command.string else { return nil }
        
        let subscription = ACSubscription(client: self, channelIdentifier: channelIdentifier, onMessage: messageHandler)
        subscriptions.insert(subscription)
        send(text: subscribe)
        
        return subscription
    }
    
    public func unsubscribe(from subscription: ACSubscription) {
        guard let command = ACCommand(type: .unsubscribe, identifier: subscription.channelIdentifier), let unsubscribe = command.string else { return }
        
        if subscriptions.remove(subscription) != nil {
            send(text: unsubscribe)
        }
    }
    
    // MARK: Callbacks
    
    public func add(_ tap: ACClientTap) {
        taps.insert(tap)
    }
    
    public func remove(_ tap: ACClientTap) {
        taps.remove(tap)
    }

    private func setupWSCallbacks() {
        socket.onConnected = { (headers) in
            self.isConnected = true
            self.taps.forEach() { $0.onConnected?(headers) }
        }
        
        socket.onDisconnected = { (reason) in
            self.isConnected = false
            self.taps.forEach() { $0.onDisconnected?(reason) }
        }
        
        socket.onText = { (text) in
            self.taps.forEach() { $0.onText?(text) }
            
            guard let message = ACMessage(string: text) else { return }
            
            self.taps.forEach() { $0.onMessage?(message) }
            self.subscriptions.forEach() { $0.onMessage(message) }
        }
    }
    
    // MARK: Deinitialization

    deinit {
        connectionMonitor?.stop()
    }
}

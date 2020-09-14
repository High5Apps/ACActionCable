
import Foundation
import os.log

public final class ACClient {
    
    // MARK: Properties
    
    public var headers: [String: String]? = nil
    
    var isConnected: Bool = false

    private var socket: ACWebSocketProtocol
    private var subscriptions: Set<ACSubscription> = []
    private var taps: Set<ACClientTap> = []
    
    private let connectionMonitor = ACConnectionMontior()
    private let options: ACClientOptions
    private let clientConcurrentQueue = DispatchQueue(label: "com.ACClient.Conccurent", attributes: .concurrent)
    private let isConnectedLock: NSLock = .init()
    private let sendLock: NSLock = .init()
    
    // MARK: Initialization

    public init(ws: ACWebSocketProtocol, headers: [String: String]? = nil, options: ACClientOptions? = nil) {
        self.socket = ws
        self.headers = headers
        self.options = options ?? ACClientOptions()
        setupWSCallbacks()
        connectionMonitor.client = self
    }
    
    // MARK: Connection management

    public func connect() {
        isConnectedLock.lock()
        socket.connect(headers: headers)
        isConnectedLock.unlock()
    }

    public func disconnect(allowReconnect: Bool = true) {
        if !allowReconnect {
            connectionMonitor.stop()
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

    public func send(data: Data, _ completion: ACEventHandler? = nil) {
        sendLock.lock()
        socket.send(data: data) {
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
        socket.onConnected = { [weak self] headers in
            guard let self = self else { return }
            self.isConnected = true
            if self.options.reconnect {
                self.connectionMonitor.start()
            }
            self.clientConcurrentQueue.async { [headers] in
                self.taps.forEach() { $0.onConnected?(headers) }
            }
        }
        socket.onDisconnected = { [weak self] reason in
            guard let self = self else { return }
            self.isConnected = false
            self.clientConcurrentQueue.async { [reason] in
                self.taps.forEach() { $0.onDisconnected?(reason) }
            }
        }
        socket.onCancelled = { [weak self] in
            guard let self = self else { return }
            self.isConnected = false
            self.clientConcurrentQueue.async {
                self.taps.forEach() { $0.onCancelled?() }
            }
        }
        socket.onText = { [weak self] text in
            guard let self = self else { return }
            
            self.clientConcurrentQueue.async { [text] in
                self.taps.forEach() { $0.onText?(text) }
            }
            
            guard let message = ACMessage(string: text) else {
                os_log("Failed to parse message from text: %@", text)
                return
            }
            
            self.clientConcurrentQueue.async { [message] in
                self.taps.forEach() { $0.onMessage?(message) }
            }
            
            self.clientConcurrentQueue.async { [message] in
                self.subscriptions.forEach() { $0.onMessage(message) }
            }
            
            switch message.type {
            case .disconnect:
                if let reconnect = message.reconnect, !reconnect {
                    self.connectionMonitor.stop()
                }
            case .ping:
                self.connectionMonitor.ping()
            default: break
            }
        }
        socket.onBinary = { [weak self] data in
            guard let self = self else { return }
            self.clientConcurrentQueue.async { [data] in
                self.taps.forEach() { $0.onBinary?(data) }
            }
        }
        socket.onPing = { [weak self] in
            guard let self = self else { return }
            self.clientConcurrentQueue.async {
                self.taps.forEach() { $0.onPing?() }
            }
        }
        socket.onPong = { [weak self] in
            guard let self = self else { return }
            self.clientConcurrentQueue.async {
                self.taps.forEach() { $0.onPong?() }
            }
        }
    }
    
    // MARK: Deinitialization

    deinit {
        connectionMonitor.stop()
    }
}

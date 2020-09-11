
import Foundation

public final class ACClient {

    public var ws: ACWebSocketProtocol
    public var isConnected: Bool = false
    public var headers: [String: String]?
    public let connectionMonitor = ACConnectionMontior()
    public var options: ACClientOptions

    private let clientConcurrentQueue = DispatchQueue(label: "com.ACClient.Conccurent", attributes: .concurrent)
    private let isConnectedLock: NSLock = .init()
    private let sendLock: NSLock = .init()
    
    private var subscriptions: Set<ACSubscription> = []

    /// callbacks
    private var onConnected: [String: [ACConnectionHandler]] = [:]
    private var onDisconnected: [ACDisconnectionHandler] = []
    private var onCancelled: [ACEventHandler] = []
    private var onText: [ACTextHandler] = []
    private var onBinary: [ACDataHandler] = []
    private var onPing: [ACEventHandler] = []
    private var onPong: [ACEventHandler] = []

    public init(ws: ACWebSocketProtocol,
                headers: [String: String]? = nil,
                options: ACClientOptions? = nil
    ) {
        self.ws = ws
        self.headers = headers
        self.options = options ?? ACClientOptions()
        setupWSCallbacks()
        connectionMonitor.client = self
    }

    public func addOnConnected(_ handler: @escaping ACConnectionHandler, identifier: String? = nil) {
        let identifier = identifier ?? UUID().uuidString
        if onConnected[identifier] == nil {
            onConnected[identifier] = []
        }
        onConnected[identifier]!.append(handler)
    }
    
    public func removeOnConnectedHandlers(with identifier: String) {
        onConnected.removeValue(forKey: identifier)
    }

    public func addOnDisconnected(_ handler: @escaping ACDisconnectionHandler) {
        onDisconnected.append(handler)
    }

    public func addOnCancelled(_ handler: @escaping ACEventHandler) {
        onCancelled.append(handler)
    }

    public func addOnText(_ handler: @escaping ACTextHandler) {
        onText.append(handler)
    }

    public func addOnBinary(_ handler: @escaping ACDataHandler) {
        onBinary.append(handler)
    }

    public func addOnPing(_ handler: @escaping ACEventHandler) {
        onPing.append(handler)
    }

    public func addOnPong(_ handler: @escaping ACEventHandler) {
        onPong.append(handler)
    }

    public func connect() {
        isConnectedLock.lock()
        ws.connect(headers: headers)
        isConnectedLock.unlock()
    }

    public func disconnect(allowReconnect: Bool = true) {
        if !allowReconnect {
            connectionMonitor.stop()
        }
        
        isConnectedLock.lock()
        ws.disconnect()
        isConnectedLock.unlock()
    }

    public func send(text: String, _ completion: ACEventHandler? = nil) {
        sendLock.lock()
        ws.send(text: text) {
            completion?()
        }
        sendLock.unlock()
    }

    public func send(data: Data, _ completion: ACEventHandler? = nil) {
        sendLock.lock()
        ws.send(data: data) {
            completion?()
        }
        sendLock.unlock()
    }
    
    // MARK: Subscriptions
    
    public func subscribe(to channelIdentifier: ACChannelIdentifier, with messageHandler: @escaping ACMessageHandler) -> ACSubscription? {
        guard let subscribe: String = try? ACSerializer.requestFrom(command: .subscribe, identifier: channelIdentifier) else { return nil }
        
        let subscription = ACSubscription(client: self, channelIdentifier: channelIdentifier, onMessage: messageHandler)
        subscriptions.insert(subscription)
        send(text: subscribe)
        
        return subscription
    }
    
    public func unsubscribe(from subscription: ACSubscription) {
        guard let unsubscribe: String = try? ACSerializer.requestFrom(command: .unsubscribe, identifier: subscription.channelIdentifier) else { return }
        if subscriptions.remove(subscription) != nil {
            send(text: unsubscribe)
        }
    }

    @discardableResult
    public func makeChannel(identifier: ACChannelIdentifier, options: ACChannelOptions? = nil) -> ACChannel {
        ACChannel(client: self, identifier: identifier, options: options)
    }

    private func setupWSCallbacks() {
        ws.onConnected = { [weak self] headers in
            guard let self = self else { return }
            self.setIsConnected(to: true)
            if self.options.reconnect {
                self.connectionMonitor.start()
            }
            self.clientConcurrentQueue.async { [headers] in
                self.onConnected.values.forEach { (closures) in
                    closures.forEach() { $0(headers) }
                }
            }
        }
        ws.onDisconnected = { [weak self] reason in
            guard let self = self else { return }
            self.setIsConnected(to: false)
            self.clientConcurrentQueue.async { [reason] in
                let closures = self.onDisconnected
                for closure in closures {
                    closure(reason)
                }
            }
        }
        ws.onCancelled = { [weak self] in
            guard let self = self else { return }
            self.setIsConnected(to: false)
            self.clientConcurrentQueue.async {
                let closures = self.onCancelled
                for closure in closures {
                    closure()
                }
            }
        }
        ws.onText = { [weak self] text in
            guard let self = self else { return }
            let message = ACSerializer.responseFrom(stringData: text)
            switch message.type {
            case .disconnect:
                if let reconnect = message.reconnect, !reconnect {
                    self.connectionMonitor.stop()
                }
            case .ping:
                self.connectionMonitor.ping()
            default: break
            }
            self.clientConcurrentQueue.async { [message] in
                self.subscriptions.forEach() { $0.onMessage(message) }
            }
            self.clientConcurrentQueue.async { [text] in
                let closures = self.onText
                for closure in closures {
                    closure(text)
                }
            }
        }
        ws.onBinary = { [weak self] data in
            guard let self = self else { return }
            self.clientConcurrentQueue.async { [data] in
                let closures = self.onBinary
                for closure in closures {
                    closure(data)
                }
            }
        }
        ws.onPing = { [weak self] in
            guard let self = self else { return }
            self.clientConcurrentQueue.async {
                let closures = self.onPing
                for closure in closures {
                    closure()
                }
            }
        }
        ws.onPong = { [weak self] in
            guard let self = self else { return }
            let closures = self.onPong
            self.clientConcurrentQueue.async {
                for closure in closures {
                    closure()
                }
            }
        }
    }

    func setIsConnected(to: Bool) {
        isConnectedLock.lock()
        isConnected = to
        isConnectedLock.unlock()
    }

    func getIsConnected() -> Bool {
        isConnectedLock.lock()
        let result = isConnected
        isConnectedLock.unlock()

        return result
    }

    deinit {
        connectionMonitor.stop()
    }
}


















import Foundation

public final class ACClient {
    
    // MARK: Properties

    public var ws: ACWebSocketProtocol
    public var isConnected: Bool = false
    public var headers: [String: String]?
    public let connectionMonitor = ACConnectionMontior()
    public var options: ACClientOptions

    private let clientConcurrentQueue = DispatchQueue(label: "com.ACClient.Conccurent", attributes: .concurrent)
    private let isConnectedLock: NSLock = .init()
    private let sendLock: NSLock = .init()
    
    private var subscriptions: Set<ACSubscription> = []
    private var taps: Set<ACClientTap> = []
    
    // MARK: Initialization

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
    
    // MARK: Connection management

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
    
    // MARK: Sending messages

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
    
    // MARK: Callbacks
    
    public func add(_ tap: ACClientTap) {
        taps.insert(tap)
    }
    
    public func remove(_ tap: ACClientTap) {
        taps.remove(tap)
    }

    private func setupWSCallbacks() {
        ws.onConnected = { [weak self] headers in
            guard let self = self else { return }
            self.setIsConnected(to: true)
            if self.options.reconnect {
                self.connectionMonitor.start()
            }
            self.clientConcurrentQueue.async { [headers] in
                self.taps.forEach() { $0.onConnected?(headers) }
            }
        }
        ws.onDisconnected = { [weak self] reason in
            guard let self = self else { return }
            self.setIsConnected(to: false)
            self.clientConcurrentQueue.async { [reason] in
                self.taps.forEach() { $0.onDisconnected?(reason) }
            }
        }
        ws.onCancelled = { [weak self] in
            guard let self = self else { return }
            self.setIsConnected(to: false)
            self.clientConcurrentQueue.async {
                self.taps.forEach() { $0.onCancelled?() }
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
                self.taps.forEach() { $0.onText?(text) }
            }
        }
        ws.onBinary = { [weak self] data in
            guard let self = self else { return }
            self.clientConcurrentQueue.async { [data] in
                self.taps.forEach() { $0.onBinary?(data) }
            }
        }
        ws.onPing = { [weak self] in
            guard let self = self else { return }
            self.clientConcurrentQueue.async {
                self.taps.forEach() { $0.onPing?() }
            }
        }
        ws.onPong = { [weak self] in
            guard let self = self else { return }
            self.clientConcurrentQueue.async {
                self.taps.forEach() { $0.onPong?() }
            }
        }
    }
    
    // MARK: isConnected

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

















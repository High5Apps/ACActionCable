//
//  ACFakeWebSocket.swift
//  ACActionCableTests
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

class ACFakeWebSocket: ACWebSocketProtocol {
    
    // MARK: Properties
    
    var url: URL
    var onConnected: ACConnectionHandler?
    var onDisconnected: ACDisconnectionHandler?
    var onText: ACTextHandler?
    
    var onConnect: ACConnectionHandler?
    var onDisconnect: ACEventHandler?
    var onSendText: ACTextHandler?
    
    // MARK: Initialization
    
    init(stringURL: String = "https://example.com",
         onConnect: ACConnectionHandler? = nil,
         onDisconnect: ACEventHandler? = nil,
         disconnectReason: String? = nil,
         onSendText: ACTextHandler? = nil) {
        url = URL(string: stringURL)!
        self.onConnect = onConnect ?? { (headers) in
            self.onConnected?(headers)
        }
        self.onDisconnect = onDisconnect ?? {
            self.onDisconnected?(disconnectReason)
        }
        self.onSendText = onSendText
    }
    
    // MARK: Connections
    
    func connect(headers: ACRequestHeaders?) {
        onConnect?(headers)
    }
    
    func disconnect() {
        onDisconnect?()
    }
    
    // MARK: Sending
    
    func send(text: String, completion: ACEventHandler?) {
        onSendText?(text)
        completion?()
    }
    
    // MARK: Fake responses
    
    func confirmSubscription(to channelIdentifier: ACChannelIdentifier) {
        let confirmation = String(format: #"{"identifier":%@,"type":"confirm_subscription"}"#, channelIdentifier.string.debugDescription)
        onText?(confirmation)
    }
}

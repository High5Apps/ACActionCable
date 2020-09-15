//
//  ACFakeWebSocket.swift
//  ACActionCableTests
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

class ACFakeWebSocket: ACWebSocketProtocol {
    var url: URL
    
    func connect(headers: ACRequestHeaders?) {
        onConnect?(headers)
    }
    
    func disconnect() {
        onDisconnect?()
    }
    
    var onConnected: ACConnectionHandler?
    var onDisconnected: ACDisconnectionHandler?
    var onText: ACTextHandler?
    
    var onConnect: ACConnectionHandler?
    var onDisconnect: ACEventHandler?
    var onSendText: ACTextHandler?
    
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
    
    func send(text: String, _ completion: ACEventHandler?) {
        onSendText?(text)
        completion?()
    }
}

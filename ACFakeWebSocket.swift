//
//  ACFakeWebSocket.swift
//  ActionCableSwiftTests
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

class ACFakeWebSocket: ACWebSocketProtocol {
    var url: URL
    
    func connect(headers: [String : String]?) {
        onConnect?(headers)
    }
    
    func disconnect() {
        onDisconnect?()
    }
    
    var onConnected: ACConnectionHandler?
    var onDisconnected: ACDisconnectionHandler?
    var onCancelled: ACEventHandler?
    var onText: ACTextHandler?
    var onBinary: ACDataHandler?
    var onPing: ACEventHandler?
    var onPong: ACEventHandler?
    
    private var onConnect: ACConnectionHandler?
    private var onDisconnect: ACEventHandler?
    private var onSendText: ACTextHandler?
    private var onSendData: ACDataHandler?
    
    init(stringURL: String = "https://example.com",
         onConnect: ACConnectionHandler? = nil,
         onDisconnect: ACEventHandler? = nil,
         disconnectReason: String? = nil,
         onSendText: ACTextHandler? = nil,
         onSendData: ACDataHandler? = nil) {
        url = URL(string: stringURL)!
        self.onConnect = onConnect ?? { (headers) in
            self.onConnected?(headers)
        }
        self.onDisconnect = onDisconnect ?? {
            self.onDisconnected?(disconnectReason)
        }
        self.onSendText = onSendText
        self.onSendData = onSendData
    }
    
    func send(data: Data) {
        onSendData?(data)
    }
    
    func send(data: Data, _ completion: (() -> Void)?) {
        onSendData?(data)
    }
    
    func send(text: String) {
        onSendText?(text)
    }
    
    func send(text: String, _ completion: (() -> Void)?) {
        onSendText?(text)
    }
}

//
//  ACStarscreamWebSocket.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/15/20.
//

import Foundation
import ACActionCable
import Starscream

class ACStarscreamWebSocket: ACWebSocketProtocol {
    
    var url: URL
    var onConnected: ACConnectionHandler?
    var onDisconnected: ACDisconnectionHandler?
    var onText: ACTextHandler?
    
    private var socket: WebSocket?

    init(stringURL: String) {
        url = URL(string: stringURL)!
    }

    func connect(headers: ACRequestHeaders?) {
        guard socket == nil else { return }
        socket = WebSocket(request: URLRequest(url: url))
        socket?.delegate = self
        socket?.request.allHTTPHeaderFields = headers
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
    }

    func send(text: String, completion: ACEventHandler?) {
        socket?.write(string: text, completion: completion)
    }
}

extension ACStarscreamWebSocket: WebSocketDelegate {
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            onConnected?(headers)
        case .disconnected(let reason, _):
            onSocketDisconnected(reason)
        case .text(let text):
            onText?(text)
        case .cancelled:
            onSocketDisconnected()
        case .error(_):
            onSocketDisconnected()
        default:
            break
        }
    }
    
    private func onSocketDisconnected(_ reason: String? = nil) {
        socket = nil
        onDisconnected?(reason)
    }
}

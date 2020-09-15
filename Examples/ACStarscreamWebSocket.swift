//
//  ACStarscreamWebSocket.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/15/20.
//

import Foundation
import ACActionCable
import Starscream

class ACWebSocket: ACWebSocketProtocol, WebSocketDelegate {

    var url: URL
    
    private var ws: WebSocket

    init(stringURL: String) {
        url = URL(string: stringURL)!
        ws = WebSocket(request: URLRequest(url: url))
        ws.delegate = self
    }

    var onConnected: ACConnectionHandler?
    var onDisconnected: ACDisconnectionHandler?
    var onText: ACTextHandler?

    func connect(headers: ACRequestHeaders?) {
        ws.request.allHTTPHeaderFields = headers
        ws.connect()
    }

    func disconnect() {
        ws.disconnect()
    }

    func send(text: String, _ completion: ACEventHandler?) {
        ws.write(string: text, completion: completion)
    }

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            onConnected?(headers)
        case .disconnected(let reason, _):
            onDisconnected?(reason)
        case .text(let string):
            onText?(string)
        default:
            break
        }
    }
}

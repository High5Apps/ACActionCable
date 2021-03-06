//
//  ACWebSocketProtocol.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/15/20.
//

import Foundation

public typealias ACRequestHeaders = [String: String]
public typealias ACConnectionHandler = (_ headers: ACRequestHeaders?) -> Void
public typealias ACDisconnectionHandler = (_ reason: String?) -> Void
public typealias ACTextHandler = (_ text: String) -> Void
public typealias ACEventHandler = () -> Void

public protocol ACWebSocketProtocol {

    var url: URL {get set}
    var onConnected: ACConnectionHandler? { get set }
    var onDisconnected: ACDisconnectionHandler? { get set }
    var onText: ACTextHandler? { get set }

    func connect(headers: ACRequestHeaders?)
    func disconnect()
    func send(text: String, completion: ACEventHandler?)
}

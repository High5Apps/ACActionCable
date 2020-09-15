//
//  ACWebSocketProtocol.swift
//  ActionCableSwift
//
//  Created by Oleh Hudeichuk on 15.03.2020.
//

import Foundation

public typealias ACConnectionHandler = (_ headers: [String: String]?) -> Void
public typealias ACDisconnectionHandler = (_ reason: String?) -> Void
public typealias ACEventHandler = () -> Void
public typealias ACTextHandler = (_ text: String) -> Void
public typealias ACDataHandler = (_ data: Data) -> Void

public protocol ACWebSocketProtocol {

    var url: URL {get set}
    func makeURL(schema: String, host: String, port: Int?, path: String?) throws -> URL
    func connect(headers: [String: String]?)
    func disconnect()

    var onConnected: ACConnectionHandler? { get set }
    var onDisconnected: ACDisconnectionHandler? { get set }
    var onCancelled: ACEventHandler? { get set }
    var onText: ACTextHandler? { get set }
    var onBinary: ACDataHandler? { get set }
    var onPing: ACEventHandler? { get set }
    var onPong: ACEventHandler? { get set }

    func send(data: Data)
    func send(data: Data, _ completion: (() -> Void)?)
    func send(text: String)
    func send(text: String, _ completion: (() -> Void)?)
}

public extension ACWebSocketProtocol {

    func makeURL(schema: String,
                 host: String,
                 port: Int? = nil,
                 path: String? = nil
    ) throws -> URL {
        var stringURL = ""
        stringURL.append("\(schema)://")
        stringURL.append("\(host)")
        stringURL += port != nil ? ":\(port!)" : ""
        stringURL += path != nil ? "/\(path!)" : ""
        guard let url = URL(string: stringURL) else { throw ACError.badURL }

        return url
    }
}

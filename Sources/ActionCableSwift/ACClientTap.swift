//
//  ACClientTap.swift
//  
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public typealias ACConnectionHandler = (_ headers: [String: String]?) -> Void
public typealias ACDisconnectionHandler = (_ reason: String?) -> Void
public typealias ACEventHandler = () -> Void
public typealias ACTextHandler = (_ text: String) -> Void
public typealias ACDataHandler = (_ data: Data) -> Void

public struct ACClientTap {
    let id: String
    
    private let onConnected: ACConnectionHandler?
    private let onDisconnected: ACDisconnectionHandler?
    private let onCancelled: ACEventHandler?
    private let onText: ACTextHandler?
    private let onBinary: ACDataHandler?
    private let onPing: ACEventHandler?
    private let onPong: ACEventHandler?
    
    public init(onConnected: ACConnectionHandler? = nil,
                onDisconnected: ACDisconnectionHandler? = nil,
                onCancelled: ACEventHandler? = nil,
                onText: ACTextHandler? = nil,
                onBinary: ACDataHandler? = nil,
                onPing: ACEventHandler? = nil,
                onPong: ACEventHandler? = nil) {
        self.id = UUID().uuidString
        self.onConnected = onConnected
        self.onDisconnected = onDisconnected
        self.onCancelled = onCancelled
        self.onText = onText
        self.onBinary = onBinary
        self.onPing = onPing
        self.onPong = onPong
    }
}

extension ACClientTap: Equatable {
    
    public static func == (lhs: ACClientTap, rhs: ACClientTap) -> Bool {
        lhs.id == rhs.id
    }
}

extension ACClientTap: Hashable {
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
}

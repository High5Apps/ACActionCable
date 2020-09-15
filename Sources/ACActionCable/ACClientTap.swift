//
//  ACClientTap.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public struct ACClientTap {
    let id: String
    
    let onConnected: ACConnectionHandler?
    let onDisconnected: ACDisconnectionHandler?
    let onCancelled: ACEventHandler?
    let onText: ACTextHandler?
    let onMessage: ACMessageHandler?
    let onBinary: ACDataHandler?
    let onPing: ACEventHandler?
    let onPong: ACEventHandler?
    
    public init(onConnected: ACConnectionHandler? = nil,
                onDisconnected: ACDisconnectionHandler? = nil,
                onCancelled: ACEventHandler? = nil,
                onText: ACTextHandler? = nil,
                onMessage: ACMessageHandler? = nil,
                onBinary: ACDataHandler? = nil,
                onPing: ACEventHandler? = nil,
                onPong: ACEventHandler? = nil) {
        self.id = UUID().uuidString
        self.onConnected = onConnected
        self.onDisconnected = onDisconnected
        self.onCancelled = onCancelled
        self.onText = onText
        self.onMessage = onMessage
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

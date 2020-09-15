//
//  ACClientTap.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public struct ACClientTap {
    
    // MARK: Properties
    
    let id: String
    
    let onConnected: ACConnectionHandler?
    let onDisconnected: ACDisconnectionHandler?
    let onText: ACTextHandler?
    let onMessage: ACMessageHandler?
    
    // MARK: Initialization
    
    public init(onConnected: ACConnectionHandler? = nil,
                onDisconnected: ACDisconnectionHandler? = nil,
                onText: ACTextHandler? = nil,
                onMessage: ACMessageHandler? = nil) {
        id = UUID().uuidString
        self.onConnected = onConnected
        self.onDisconnected = onDisconnected
        self.onText = onText
        self.onMessage = onMessage
    }
}

// MARK: Equatable

extension ACClientTap: Equatable {
    
    public static func == (lhs: ACClientTap, rhs: ACClientTap) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: Hashable

extension ACClientTap: Hashable {
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
}

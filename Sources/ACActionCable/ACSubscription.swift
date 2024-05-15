//
//  ACSubscription.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public class ACSubscription {
    
    // MARK: Properties
    
    let channelIdentifier: ACChannelIdentifier
    let onMessage: ACMessageHandler
        
    private unowned var client: ACClient
    
    // MARK: Initialization
    
    init(client: ACClient, channelIdentifier: ACChannelIdentifier, onMessage: @escaping ACMessageHandler) {
        self.client = client
        self.channelIdentifier = channelIdentifier
        self.onMessage = onMessage
    }
    
    // MARK: Sending
    
    public func send<T: Encodable>(object: T, completion: ACEventHandler? = nil) {
        guard let command = ACCommand(type: .message, identifier: channelIdentifier, object: object) else { return }
        client.send(command, completion: completion)
    }
    
    public func send(action: String, completion: ACEventHandler? = nil) {
        guard let command = ACCommand(type: .message, identifier: channelIdentifier, action: action) else { return }
        client.send(command)
    }
}

// MARK: Equatable

extension ACSubscription: Equatable {
    
    public static func == (lhs: ACSubscription, rhs: ACSubscription) -> Bool {
        lhs.channelIdentifier == rhs.channelIdentifier
    }
}

// MARK: Hashable

extension ACSubscription: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(channelIdentifier.string)
    }
}

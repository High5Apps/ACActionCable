//
//  ACSubscription.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public class ACSubscription {
    
    let channelIdentifier: ACChannelIdentifier
    let onMessage: ACMessageHandler
    
    private let messageQueue = DispatchQueue(label: "com.ACSubscription.messageQueue")
    
    private unowned var client: ACClient
    
    public init(client: ACClient, channelIdentifier: ACChannelIdentifier, onMessage: @escaping ACMessageHandler) {
        self.client = client
        self.channelIdentifier = channelIdentifier
        self.onMessage = onMessage
    }

    public func send(actionName: String, data: [String: Any]? = nil, completion: ACEventHandler? = nil) {
        messageQueue.async { [weak self] in
            guard let self = self else { return }
            guard let command = ACCommand(type: .message, identifier: self.channelIdentifier, action: actionName, data: data), let message = command.string else { return }
            self.client.send(text: message) { completion?() }
        }
    }
}

extension ACSubscription: Equatable {
    
    public static func == (lhs: ACSubscription, rhs: ACSubscription) -> Bool {
        lhs.channelIdentifier == rhs.channelIdentifier
    }
}

extension ACSubscription: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(channelIdentifier.string)
    }
}

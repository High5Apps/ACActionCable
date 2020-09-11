//
//  File.swift
//  
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public class ACSubscription {
    
    let channelIdentifier: ACChannelIdentifier
    
    private let onText: ACTextHandler
    private let messageQueue = DispatchQueue(label: "com.ACSubscription.messageQueue")
    
    private unowned var client: ACClient
    
    public init(client: ACClient, channelIdentifier: ACChannelIdentifier, onText: @escaping ACTextHandler) {
        self.client = client
        self.channelIdentifier = channelIdentifier
        self.onText = onText
    }

    public func send(actionName: String, data: [String: Any] = [:], completion: ACEventHandler? = nil) {
        messageQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let text: String = try ACSerializer.requestFrom(command: .message, action: actionName, identifier: self.channelIdentifier, data: data)
                self.client.send(text: text) { completion?() }
            } catch {
                fatalError(error.localizedDescription)
            }
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

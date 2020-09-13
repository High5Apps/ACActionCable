//
//  ACMessage.swift
//  
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public enum ACCommand: String {
    case subscribe
    case unsubscribe
    case message
}

public enum ACError: Error, CustomStringConvertible {
    case badURL
    case badAction
    case badDictionary
    case badCommand
    case badStringData
    case badDictionaryData

    public var description: String {
        switch self {
        case .badURL:
            return "BAD URL. Please check schema, host, port and path"
        case .badAction:
            return "ACTION NOT FOUND"
        case .badDictionary:
            return "CONVERTING DICTIONARY TO JSON STRING FAILED"
        case .badCommand:
            return "COMMAND NOT FOUND"
        case .badStringData:
            return "CONVERTING STRING TO DATA FAILED"
        case .badDictionaryData:
            return "CONVERTING DATA TO DICTIONARY FAILED"
        }
    }

    public var localizedDescription: String { description }
}

public struct ACMessage {

    public var type: ACMessageType
    public var message: [String: Any]? // not string
    public var identifier: ACChannelIdentifier?
    public var disconnectReason: DisconnectReason?
    public var reconnect: Bool?

    public init(type: ACMessageType, message: [String: Any]? = nil, identifier: ACChannelIdentifier? = nil, disconnectReason: DisconnectReason? = nil, reconnect: Bool? = nil) {
        self.type = type
        self.message = message
        self.identifier = identifier
        self.disconnectReason = disconnectReason
        self.reconnect = reconnect
    }
}

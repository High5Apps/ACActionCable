//
//  ACCommand.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/12/20.
//

import Foundation

public struct ACCommand {
    
    // MARK: Properties
    
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()
    
    var string: String? {
        json(from: dictionary)
    }
    
    private var type: ACCommandType
    private var identifier: ACChannelIdentifier
    private var data: [String: Any]?
    
    private var dictionary: [String: Any] {
        var dictionary: [String: Any] = [
            "command": type.rawValue,
            "identifier": identifier.string,
        ]
        
        if type == .message {
            let data = self.data ?? [:]
            dictionary["data"] = json(from: data)
        }
        
        return dictionary
    }
    
    // MARK: Initialization
    
    init?(type: ACCommandType, identifier: ACChannelIdentifier, action: String? = nil) {
        self.type = type
        self.identifier = identifier

        if type == .message {
            guard let action else { return nil }

            self.data = ["action": action]
        }
    }
    
    init?<T: Encodable>(type: ACCommandType, identifier: ACChannelIdentifier, object: T) {
        self.type = type
        self.identifier = identifier

        // special handling of data
        guard let data = try? Self.encoder.encode(object), let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        self.data = jsonObject as? [String: Any]
    }
    
    // MARK: Helpers
    
    private func json(from dictionary: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .sortedKeys) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: ACCommandType

enum ACCommandType: String {
    case subscribe
    case unsubscribe
    case message
}

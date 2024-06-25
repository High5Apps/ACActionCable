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
    
    init?(type: ACCommandType, identifier: ACChannelIdentifier, action: String? = nil, object: Encodable? = nil) {
        self.type = type
        self.identifier = identifier

        if let object, let data = try? Self.encoder.encode(object) {
            self.data = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        }

        if type == .message, let action {
            self.data = self.data ?? [:]
            self.data?["action"] = action
        }

        if type == .message && (self.data ?? [:]).isEmpty { return nil }
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

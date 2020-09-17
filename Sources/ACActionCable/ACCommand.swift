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
    private var action: String?
    private var data: [String: Any]?
    
    private var dictionary: [String: Any] {
        var dictionary: [String: Any] = [
            "command": type.rawValue,
            "identifier": identifier.string,
        ]
        
        if type == .message {
            var data = self.data ?? [:]
            data["action"] = action!
            dictionary["data"] = json(from: data)
        }
        
        return dictionary
    }
    
    // MARK: Initialization
    
    init?(type: ACCommandType, identifier: ACChannelIdentifier, action: String? = nil) {
        self.type = type
        self.identifier = identifier
        self.action = action
        if type == .message {
            guard action != nil else { return nil }
        }
    }
    
    init?<T: Encodable>(type: ACCommandType, identifier: ACChannelIdentifier, action: String, object: T) {
        self.type = type
        self.identifier = identifier
        self.action = action
        let namedEncodable = ACNamedEncodable<T>(encodable: object)
        guard let data = try? Self.encoder.encode(namedEncodable), let object = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = object as? [String: Any] else { return nil }
        self.data = dictionary
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

// MARK: ACNamedEncodable

private struct ACNamedEncodable<T: Encodable>: Encodable {
    let encodable: T
    
    func encode(to encoder: Encoder) throws {
        let typeName = String(describing: T.self)
        var container = encoder.container(keyedBy: DynamicKey.self)
        try container.encode(encodable, forKey: DynamicKey(stringValue: typeName)!)
    }
}

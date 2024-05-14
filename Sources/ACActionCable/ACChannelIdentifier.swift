//
//  ACChannelIdentifier.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public struct ACChannelIdentifier {
    
    // MARK: Properties
    
    let dictionary: [String: Any]
    let string: String
    
    // MARK: Initialization
    
    public init?(channelName: String, identifier: [String: Any] = [:]) {
        var dictionary = identifier
        dictionary["channel"] = channelName
        self.dictionary = dictionary
        
        guard let string = Self.json(from: self.dictionary) else { return nil }
        self.string = string
    }
    
    private init?(string: String) {
        self.string = string
        
        guard let data = string.data(using: .utf8), let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        self.dictionary = dictionary
    }
    
    // MARK: Helpers
    
    private static func json(from dictionary: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .sortedKeys) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: Equatable

extension ACChannelIdentifier: Equatable {
    
    public static func == (lhs: ACChannelIdentifier, rhs: ACChannelIdentifier) -> Bool {
        lhs.string == rhs.string
    }
}

// MARK: Hashable

extension ACChannelIdentifier: Hashable {
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(string)
    }
}

// MARK: Decodable

extension ACChannelIdentifier: Decodable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let string = try? container.decode(String.self), let channelIdentifier = ACChannelIdentifier(string: string) else {
            throw DecodingError.typeMismatch(ACChannelIdentifier.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Failed to parse ACChannelIdentifier"))
        }
        self = channelIdentifier
    }
}

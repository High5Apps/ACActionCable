//
//  ACCommand.swift
//  ActionCableSwift
//
//  Created by Julian Tigler on 9/12/20.
//

import Foundation
import os.log

public enum ACCommandType: String {
    case subscribe
    case unsubscribe
    case message
}

public struct ACCommand {
    private var type: ACCommandType
    private var identifier: ACChannelIdentifier
    private var action: String?
    private var data: [String: Any]?
        
    public var string: String? {
        json(from: dictionary)
    }
    
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
    
    public init?(type: ACCommandType, identifier: ACChannelIdentifier, action: String? = nil, data: [String: Any]? = nil) {
        self.type = type
        self.identifier = identifier
        self.action = action
        self.data = data
        if type == .message {
            guard action != nil else {
                os_log("ACCommand action cannot be nil when type is message")
                return nil
            }
        }
    }
    
    private func json(from dictionary: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .sortedKeys) else {
            os_log("ACCommand failed to serialize dictionary")
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

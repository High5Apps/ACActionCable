//
//  ACSerializer.swift
//  ActionCableSwift
//
//  Created by Oleh Hudeichuk on 16.03.2020.
//

import Foundation
import SwiftExtensionsPack

public class ACSerializer {

    public class func requestFrom(command: ACCommand,
                                  action: String? = nil,
                                  identifier: ACChannelIdentifier,
                                  data: [String: Any] = [:]
    ) throws -> String {
        try makeRequestDictionary(command: command,
                                  action: action,
                                  identifier: identifier,
                                  data: data
        ).toJSON()
    }

    public class func requestFrom(command: ACCommand,
                                  action: String? = nil,
                                  identifier: ACChannelIdentifier,
                                  data: [String: Any] = [:]
    ) throws -> Data {
        try makeRequestDictionary(command: command,
                                  action: action,
                                  identifier: identifier,
                                  data: data
        ).toJSONData()
    }

    private class func makeRequestDictionary(command: ACCommand,
                                             action: String? = nil,
                                             identifier: ACChannelIdentifier,
                                             data: [String: Any]
    ) throws -> [String: Any] {
        switch command {
        case .message:
            guard let action = action else { throw ACError.badAction }
            var data: [String : Any] = data
            data["action"] = action
            let payload: [String : Any] = [
                "command": command.rawValue,
                "identifier": identifier.string,
                "data": try data.toJSON()
            ]
            return payload
        case .subscribe, .unsubscribe:
            let payload: [String : Any] = [
                "command": command.rawValue,
                "identifier": identifier.string,
            ]
            return payload
        }
    }
}

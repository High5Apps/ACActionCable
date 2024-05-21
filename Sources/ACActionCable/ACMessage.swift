//
//  ACMessage.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/12/20.
//

import Foundation

public typealias ACMessageHandler = (ACMessage) -> Void

public struct ACMessage: Decodable {
    
    // MARK: Properties
    
    private static var messageTypes: [String: Decodable.Type] = [:]

    public static var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    public var type: ACMessageType?
    public var body: ACMessageBody?
    public var identifier: ACChannelIdentifier?
    public var disconnectReason: ACDisconnectReason?
    public var reconnect: Bool?
    
    enum CodingKeys: String, CodingKey {
        case type
        case identifier
        case body = "message"
        case disconnectReason = "reason"
        case reconnect
    }

    public static func register<A: Decodable>(type: A.Type, forChannelIdentifier identifier: ACChannelIdentifier) {
        messageTypes[identifier.string] = type
    }

    public static func unregisterType(forChannelIdentifier identifier: ACChannelIdentifier) {
        messageTypes.removeValue(forKey: identifier.string)
    }

    public static func unregisterAllTypes() {
        messageTypes.removeAll()
    }

    // MARK: Initialization
    
    init?(string: String) {
        guard let data = string.data(using: .utf8), let message = try? Self.decoder.decode(ACMessage.self, from: data) else { return nil }
        self = message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decodeIfPresent(ACMessageType.self, forKey: .type)
        identifier = try container.decodeIfPresent(ACChannelIdentifier.self, forKey: .identifier)
        disconnectReason = try container.decodeIfPresent(ACDisconnectReason.self, forKey: .disconnectReason)
        reconnect = try container.decodeIfPresent(Bool.self, forKey: .reconnect)

        // special handling for message BODY
        if let identifier, let messageType = Self.messageTypes[identifier.string] {
            let bodyObject = try container.decodeIfPresent(messageType, forKey: .body)
            body = ACMessageBody.object(bodyObject)
        } else {
            body = try container.decodeIfPresent(ACMessageBody.self, forKey: .body)
        }
    }
}

// MARK: ACMessageType

public enum ACMessageType: String, Decodable {
    case confirmSubscription = "confirm_subscription"
    case rejectSubscription = "reject_subscription"
    case welcome
    case disconnect
    case ping
    case message
}

// MARK: ACMessageBody

public enum ACMessageBody: Decodable {
    case ping(Int)
    case object(Any?)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .ping(value)
        } else if let value = try? container.decode(ACMessageBodySingleObject.self) {
            self = .object(value.object)
        } else {
            throw DecodingError.typeMismatch(ACMessageBody.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to parse message body"))
        }
    }
}

// MARK: ACMessageBodyObject

public struct ACMessageBodySingleObject: Decodable {
    public let object: Any?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        guard container.allKeys.count == 1, let firstKey = container.allKeys.first else {
            throw DecodingError.typeMismatch(ACMessageBodySingleObject.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Expected message container to only have one top-level key"))
        }
        
        let key = firstKey.stringValue
        guard let decoder = Self.decoders[key] else {
            throw DecodingError.typeMismatch(ACMessageBodySingleObject.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "No message decoder registered for key: \(key)"))
        }
        
        object = try? decoder(container)
    }
    
    private typealias BodyDecoder = (KeyedDecodingContainer<DynamicKey>) throws -> Any
    private static var decoders: [String: BodyDecoder] = [:]
    
    public static func register<A: Decodable>(type: A.Type, forKey key: String? = nil) {
        let pascalCaseTypeName = String(describing: type)
        let camelCaseTypeName = pascalCaseTypeName.prefix(1).lowercased() + pascalCaseTypeName.dropFirst()

        decoders[camelCaseTypeName] = { container in
            try container.decode(A.self, forKey: DynamicKey(stringValue: key ?? camelCaseTypeName)!)
        }
    }
}

// MARK: DynamicKey

struct DynamicKey: CodingKey {
    var intValue: Int?
    var stringValue: String
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = intValue.description
    }
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
}

// MARK: ACDisconnectReason

public enum ACDisconnectReason: String, Decodable {
    case unauthorized
    case invalidRequest = "invalid_request"
    case serverRestart = "server_restart"
}

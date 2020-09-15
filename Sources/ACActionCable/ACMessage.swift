//
//  ACMessage.swift
//  ACActionCable
//
//  Created by Julian Tigler on 9/12/20.
//

import Foundation

public struct ACMessage: Decodable {
    
    public static var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    public var type: ACMessageType?
    public var body: Body?
    public var identifier: ACChannelIdentifier?
    public var disconnectReason: DisconnectReason?
    public var reconnect: Bool?
    
    enum CodingKeys: String, CodingKey {
        case type
        case identifier
        case body = "message"
        case disconnectReason = "reason"
        case reconnect
    }
    
    init?(string: String) {
        guard let data = string.data(using: .utf8), let message = try? Self.decoder.decode(ACMessage.self, from: data) else { return nil }
        self = message
    }
}

public enum ACMessageType: String, Decodable {
    case confirmSubscription = "confirm_subscription"
    case rejectSubscription = "reject_subscription"
    case welcome
    case disconnect
    case ping
    case message
}

public enum Body: Decodable {
    case ping(Date)
    case dictionary(BodyObject)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Date.self) {
            self = .ping(value)
        } else if let value = try? container.decode(BodyObject.self) {
            self = .dictionary(value)
        } else {
            throw DecodingError.typeMismatch(Body.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to parse message body"))
        }
    }
}

public struct BodyObject: Decodable {
    public let object: Any?
    
    private enum CodingKeys: String, CodingKey {
        case object
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        guard container.allKeys.count == 1, let firstKey = container.allKeys.first else {
            throw DecodingError.typeMismatch(BodyObject.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Expected message container to only have one top-level key"))
        }
        
        let key = firstKey.stringValue
        guard let decoder = Self.decoders[key] else {
            throw DecodingError.typeMismatch(BodyObject.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "No message decoder registered for key: \(key)"))
        }
        
        object = try? decoder(container)
    }
    
    private typealias BodyDecoder = (KeyedDecodingContainer<DynamicKey>) throws -> Any
    private static var decoders: [String: BodyDecoder] = [:]
    
    public static func register<A: Decodable>(_ type: A.Type) {
        let pascalCaseTypeName = String(describing: type)
        let camelCaseTypeName = pascalCaseTypeName.prefix(1).lowercased() + pascalCaseTypeName.dropFirst()

        decoders[camelCaseTypeName] = { container in
            try container.decode(A.self, forKey: DynamicKey(stringValue: camelCaseTypeName)!)
        }
    }
}

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

public enum DisconnectReason: String, Decodable {
    case unauthorized
    case invalidRequest = "invalid_request"
    case serverRestart = "server_restart"
}

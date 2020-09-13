//
//  ACDecodableMessage.swift
//  ActionCableSwift
//
//  Created by Julian Tigler on 9/12/20.
//

import Foundation

public struct ACDecodableMessage: Decodable {

    public var type: ACMessageType?
    public var body: Body?
    public var identifier: ACChannelIdentifier?
    public var disconnectReason: DisconnectReason?
    public var reconnect: Bool?
    
    enum CodingKeys: String, CodingKey {
        case type
        case identifier
        case body = "message"
        case disconnectReason = "disconnect_reason"
        case reconnect
    }
}

public enum ACMessageType: String, Decodable {
    case confirmSubscription = "confirm_subscription"
    case rejectSubscription = "reject_subscription"
    case cancelSubscription = "cancel_subscription"
    case hibernateSubscription = "hibernate_subscription"
    case welcome = "welcome"
    case disconnect = "disconnect"
    case ping = "ping"
    case message = "message"
    case unrecognized = "___unrecognized"

    init(string: String) {
        switch(string) {
        case ACMessageType.welcome.rawValue:
            self = ACMessageType.welcome
        case ACMessageType.ping.rawValue:
            self = ACMessageType.ping
        case ACMessageType.disconnect.rawValue:
            self = ACMessageType.disconnect
        case ACMessageType.confirmSubscription.rawValue:
            self = ACMessageType.confirmSubscription
        case ACMessageType.rejectSubscription.rawValue:
            self = ACMessageType.rejectSubscription
        case ACMessageType.cancelSubscription.rawValue:
            self = ACMessageType.cancelSubscription
        case ACMessageType.hibernateSubscription.rawValue:
            self = ACMessageType.hibernateSubscription
        default:
            self = ACMessageType.unrecognized
        }
    }
}

public enum Body: Decodable {
    case int(Int)
    case dictionary(BodyObject)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(BodyObject.self) {
            self = .dictionary(value)
        } else {
            throw DecodingError.typeMismatch(Body.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to parse message body"))
        }
    }
}

public struct BodyObject: Decodable {
    let object: Any?
    
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
    
    static func register<A: Decodable>(_ type: A.Type, for typeName: String) {
        decoders[typeName] = { container in
            try container.decode(A.self, forKey: DynamicKey(stringValue: typeName)!)
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
    case unauthorized = "unauthorized"
    case invalidRequest = "invalid_request"
    case serverRestart = "server_restart"
    case unrecognized = "___unrecognized"
    
    init(string: String) {
        switch(string) {
        case DisconnectReason.unauthorized.rawValue:
            self = DisconnectReason.unauthorized
        case DisconnectReason.invalidRequest.rawValue:
            self = DisconnectReason.invalidRequest
        case DisconnectReason.serverRestart.rawValue:
            self = DisconnectReason.serverRestart
        default:
            self = DisconnectReason.unrecognized
        }
    }
}

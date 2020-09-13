//
//  ACError.swift
//  ActionCableSwift
//
//  Created by Julian Tigler on 9/12/20.
//

import Foundation

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

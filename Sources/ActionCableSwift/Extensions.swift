//
//  Extensions.swift
//  ActionCableSwift
//
//  Created by Oleh Hudeichuk on 16.03.2020.
//

import Foundation

extension String {

    func toChannelIdentifier() throws -> ACChannelIdentifier {
        guard
            let data = data(using: .utf8)
            else { throw ACError.badStringData }
        guard
            let dict = try JSONSerialization.jsonObject(with: data) as? ACChannelIdentifier
            else { throw ACError.badDictionaryData }

        return dict
    }
}

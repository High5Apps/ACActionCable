//
//  ACClientOptions.swift
//  
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public struct ACClientOptions {
    let reconnect: Bool

    public init(reconnect: Bool = false) {
        self.reconnect = reconnect
    }
}

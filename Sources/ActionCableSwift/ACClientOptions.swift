//
//  ACClientOptions.swift
//  
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public struct ACClientOptions {
    #if DEBUG
    public var debug = true
    #else
    public var debug = false
    #endif

    public var reconnect: Bool = false

    public init() {}

    public init(debug: Bool, reconnect: Bool) {
        self.debug = debug
        self.reconnect = reconnect
    }
}

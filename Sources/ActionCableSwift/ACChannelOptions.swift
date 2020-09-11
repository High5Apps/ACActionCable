//
//  ACChannelOptions.swift
//  
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public struct ACChannelOptions {

    public var buffering = false
    public var autoSubscribe = false
    public var resubscribeOnReconnection = false

    public init() {}

    public init(buffering: Bool, autoSubscribe: Bool, resubscribeOnReconnection: Bool) {
        self.buffering = buffering
        self.autoSubscribe = autoSubscribe
        self.resubscribeOnReconnection = resubscribeOnReconnection
    }
}

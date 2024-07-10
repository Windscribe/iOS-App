//
//  DNSValue.swift
//  Windscribe
//
//  Created by Andre Fonseca on 02/07/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

struct DNSValue: Codable, Equatable {
    enum DNSValueType: String, Codable {
        case ipAddress
        case overHttps
        case overTLS
        case empty
    }

    let type: DNSValueType
    let value: String
    let servers: [String]
}

extension DNSValue: CustomStringConvertible {
    var description: String {
        return "Type: \(type) Value: \(value) Servers: \(servers)"
    }
}

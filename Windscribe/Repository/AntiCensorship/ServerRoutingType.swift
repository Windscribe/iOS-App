//
//  ServerRoutingType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/03/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

enum ServerRoutingType: String, CaseIterable {
    case auto
    case regular
    case alternate

    var title: String {
        switch self {
        case .auto: "Auto"
        case .regular: "Regular"
        case .alternate: "Alternate"
        }
    }

    var value: Int {
        switch self {
        case .auto: -1
        case .regular: 0
        case .alternate: 1
        }
    }

    var apiValue: Int32 {
        Int32(value)
    }

    static func getTypeFrom(id: Int) -> ServerRoutingType {
        if id == ServerRoutingType.alternate.value {
            return .alternate
        } else if id == ServerRoutingType.regular.value {
            return .regular
        }
        return .auto
    }
}

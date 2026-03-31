//
//  ConnectionsRouteID.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum ConnectionsRouteID: BaseRouteID {
    case networkOptions
    case networkSettings(network: WifiNetworkModel)
    case antiCensorshipOptions

    var id: Int {
        switch self {
        case .networkOptions: 1
        case .networkSettings: 2
        case .antiCensorshipOptions: 3
        }
    }
}

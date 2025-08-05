//
//  ShakeForDataRouteID.swift
//  Windscribe
//
//  Created by Andre Fonseca on 17/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum ShakeForDataRouteID: BaseRouteID {
    case leaderboard
    case shakeGame
    case results

    var id: Int {
        switch self {
        case .leaderboard: 1
        case .shakeGame: 2
        case .results: 3
        }
    }
}

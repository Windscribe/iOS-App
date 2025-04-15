//
//  NavigationRoute.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-25.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum NavigationRouteID: Identifiable, Hashable {
    case login
    case signup(claimGhostAccount: Bool)
    case emergency
    case main

    var id: NavigationRouteID { self }
}

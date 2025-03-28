//
//  NavigationRoute.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-25.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum NavigationRouteID: Identifiable {
    case login
    case signup
    case emergency
    case main

    var id: Self { self }
}

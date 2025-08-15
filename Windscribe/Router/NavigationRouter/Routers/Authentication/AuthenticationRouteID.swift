//
//  NavigationRoute.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-25.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum AuthenticationRouteID: BaseRouteID {
    case login
    case signup(claimGhostAccount: Bool)
    case emergency
    case main
    case enterEmail
    case restrictiveNetwork

    var id: AuthenticationRouteID { self }
}

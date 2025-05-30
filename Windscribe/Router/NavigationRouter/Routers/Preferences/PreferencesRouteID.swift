//
//  PreferencesRouteID.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum PreferencesRouteID: Int, BaseRouteID, CaseIterable {
    case general = 0
    case account
    case connection
    case robert
    case referData
    case lookAndFeel
    case help
    case about

    case ghostAccount
    case enterEmail
    case login
    case signupGhost
    case confirmEmail

    case networkSecurity

    var id: PreferencesRouteID { self }
}

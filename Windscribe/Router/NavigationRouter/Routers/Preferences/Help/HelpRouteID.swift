//
//  HelpRouteID.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum HelpRouteID: Int, BaseRouteID, CaseIterable {
    case sendTicket = 0
    case advancedParameters
    case debugLog

    var id: HelpRouteID { self }
}

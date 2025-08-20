//
//  ScreenTestRouteID.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-19.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum ScreenTestRouteID: Int, BaseRouteID, CaseIterable {
    case accountStateBanned = 0
    case accountStateOOD
    case accountStatePlan
    case enterCredentials
    case locationPermission
    case maintenanceLocation
    case privacyInformation
    case pushNotification
    case restrictiveNetwork
    case shakeForData

    var id: ScreenTestRouteID { self }
}

//
//  ScreenTestItemType.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-19.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SwiftUI

enum ScreenTestItemType: Int, MenuCategoryRowType, CaseIterable {
    case accountStateBanned
    case accountStateOOD
    case accountStatePlan
    case enterCredentials
    case locationPermission
    case maintenanceLocation
    case privacyInformation
    case pushNotification
    case shakeForData
    case restrictiveNetwork

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .accountStateBanned:
            "Account State Banned"
        case .accountStateOOD:
            "Account State OOD"
        case .accountStatePlan:
            "Account State Plan"
        case .enterCredentials:
            "Enter Credentials"
        case .locationPermission:
            "Location Permission"
        case .maintenanceLocation:
            "Maintenance Location"
        case .privacyInformation:
            "Privacy Information"
        case .pushNotification:
            "Push Notification"
        case .shakeForData:
            "Shake For Data"
        case .restrictiveNetwork:
            "Restrictive Network"
        }
    }

    var imageName: String? {
        switch self {
        case .accountStateBanned:
            ImagesAsset.Preferences.account
        case .accountStateOOD:
            ImagesAsset.Preferences.account
        case .accountStatePlan:
            ImagesAsset.Preferences.account
        case .enterCredentials:
            ImagesAsset.enterCredentials
        case .locationPermission:
            ImagesAsset.locationIcon
        case .maintenanceLocation:
            ImagesAsset.locationIcon
        case .privacyInformation:
            ImagesAsset.Preferences.about
        case .pushNotification:
            ImagesAsset.pushNotifications
        case .shakeForData:
            ImagesAsset.ShakeForData.icon
        case .restrictiveNetwork:
            ImagesAsset.wifi
        }
    }

    var actionImageName: String? {
        ImagesAsset.serverWhiteRightArrow
    }

    var tint: UIColor? {
        nil
    }

    func tintColor(_ isDarkMode: Bool) -> Color {
        .from(.titleColor, isDarkMode)
    }
}

extension ScreenTestItemType {
    var routeID: ScreenTestRouteID? {
        switch self {
        case .accountStateBanned: return .accountStateBanned
        case .accountStateOOD: return .accountStateOOD
        case .accountStatePlan: return .accountStatePlan
        case .enterCredentials: return .enterCredentials
        case .locationPermission: return .locationPermission
        case .maintenanceLocation: return .maintenanceLocation
        case .privacyInformation: return .privacyInformation
        case .pushNotification: return .pushNotification
        case .shakeForData: return .shakeForData
        case .restrictiveNetwork: return .restrictiveNetwork
        }
    }
}
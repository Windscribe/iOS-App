//
//  AccountStatusType.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-29.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

enum AccountStatusType: Equatable {
    case banned
    case outOfData
    case proPlanExpired

    var imageName: String {
        switch self {
        case .banned:
            return ImagesAsset.Garry.angry
        case .outOfData:
            return ImagesAsset.Garry.noData
        case .proPlanExpired:
            return ImagesAsset.Garry.sad
        }
    }

    var title: String {
        switch self {
        case .banned:
            return TextsAsset.Banned.title
        case .outOfData:
            return TextsAsset.OutOfData.title
        case .proPlanExpired:
            return TextsAsset.ProPlanExpired.title
        }
    }

    var description: String {
        switch self {
        case .banned:
            return TextsAsset.Banned.description
        case .outOfData:
            return TextsAsset.OutOfData.description
        case .proPlanExpired:
            return TextsAsset.ProPlanExpired.description
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .banned:
            return TextsAsset.Banned.action
        case .outOfData:
            return TextsAsset.OutOfData.action
        case .proPlanExpired:
            return TextsAsset.ProPlanExpired.action
        }
    }

    var secondaryButtonTitle: String? {
        switch self {
        case .banned:
            return nil  // No secondary button for banned accounts
        case .outOfData:
            return TextsAsset.OutOfData.cancel
        case .proPlanExpired:
            return TextsAsset.ProPlanExpired.cancel
        }
    }

    var canTakeAction: Bool {
        switch self {
        case .banned:
            return true  // Done button is enabled to dismiss
        case .outOfData, .proPlanExpired:
            return true
        }
    }
}

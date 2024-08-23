//
//  PopupTypes.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 13/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum PopupTypes {
    case support
    case error(String)
    case rateUs
    case getMoreData
    case confirmEmail
    case addeEmail

    var title: String {
        switch self {
        case .support: PopupsTV.support
        case .error: TextsAsset.error
        case .getMoreData: TextsAsset.getMoreData
        case .confirmEmail: TextsAsset.EmailView.confirmEmail
        case .addeEmail: TextsAsset.addEmail
        default: ""
        }
    }

    var header: String {
        switch self {
        case .support:Links.support
        case .rateUs: Constants.appName
        default: ""
        }
    }

    var body: String {
        switch self {
        case .support: PopupsTV.supportBody
        case .rateUs: TextsAsset.RateUs.description
        case let .error(body): body
        case .getMoreData: "Either sign up to increase it to 10GB/Month, or upgrade it and get rid of the limits completely."
        case .addeEmail, .confirmEmail: TextsAsset.EnterEmail.description
        }
    }
}

//
//  RouteIDTv.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 25/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum RouteID {
    // MARK: - Main

    case login
    case signup(claimGhostAccount: Bool)
    case mainMenu
    case home
    case forgotPassword
    case preferences
    case serverList(bestLocation: BestLocationModel?)
    case locationListDetail(location: LocationModel, delegate: LocationsListTableViewDelegate?)
    case upgrade(promoCode: String?, pcpID: String?, shouldBeRoot: Bool = false)
    case confirmEmail(delegate: ConfirmEmailViewControllerDelegate?)
    case addEmail
    case enterEmail
    case support
    case error(body: String)
    case rateUs
    case getMoreData
    case newsFeed
    case bannedAccountPopup
    case outOfDataAccountPopup
    case proPlanExpireddAccountPopup
    case privacyView(completionHandler: () -> Void)
    case emergency
}

enum PreferencesRouteID {
    case general
    case account
    case connection
    case robert
    case referData
    case lookAndFeel
    case help
    case about
    case logout
}

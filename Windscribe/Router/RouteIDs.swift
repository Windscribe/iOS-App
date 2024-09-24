//
//  RouteID.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-13.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
enum RouteID {
    // MARK: - Main
    case login
    case signup(claimGhostAccount: Bool)
    case home
    case emergency
    case mainMenu
    // MARK: - Preferences Menu
    case advanceParams
    case help
    case viewLog
    case enterEmail
    case confirmEmail(delegate: ConfirmEmailViewControllerDelegate?)
    case general
    case ghostAccount
    case account
    case robert
    case about
    case shareWithFriends
    case connection
    case language
    case enterEmailVC
    case networkSecurity
    case network(with: WifiNetwork)
    case submitTicket
    case locationPermission(delegate: DisclosureAlertDelegate, denied: Bool)
    // MARK: - Pop Up
    case shakeForDataPopUp
    case shakeForDataView
    case shakeForDataResult(shakeCount: Int)
    case shakeLeaderboards
    case upgrade(promoCode: String?, pcpID: String?)
    case bannedAccountPopup(animated: Bool)
    case outOfDataAccountPopup
    case proPlanExpireddAccountPopup
    case errorPopup(message: String, dismissAction: (() -> Void)?)
    case newsFeedPopup
    case setPreferredProtocolPopup
    case privacyView(completionHandler: () -> Void)
    case pushNotifications
    case enterCredentials(config: CustomConfigModel, isUpdating: Bool)
    case infoPrompt(title: String, actionValue: String,
                    justDismissOnAction: Bool, delegate: InfoPromptViewDelegate?)
    case trustedNetwork
    // MARK: - Protocol View
    case sendDebugLogCompleted(delegate: SendDebugLogCompletedVCDelegate )
    case protocolSetPreferred(type: ProtocolViewType, delegate: ProtocolSwitchVCDelegate?, protocolName: String)
    case maintenanceLocation
    case protocolSwitchVC(delegate: ProtocolSwitchVCDelegate?, type: ProtocolFallbacksType)
    case rateUsPopUp
}

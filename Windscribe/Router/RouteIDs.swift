//
//  RouteIDs.swift
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
    case confirmEmail
    case general
    case ghostAccount
    case account
    case robert
    case lookFeel
    case about
    case shareWithFriends
    case connection
    case language
    case networkSecurity
    case network(with: WifiNetwork)
    case submitTicket

    // MARK: - Pop Up
    case locationPermission
    case shakeForDataPopUp
    case upgrade(promoCode: String?, pcpID: String?)
    case bannedAccountPopup
    case outOfDataAccountPopup
    case proPlanExpireddAccountPopup
    case newsFeedPopup
    case privacyView
    case pushNotifications
    case enterCredentials(config: CustomConfigModel, isUpdating: Bool)

    // MARK: - Protocol View

    case sendDebugLogCompleted(delegate: SendDebugLogCompletedVCDelegate)
    case protocolSetPreferred(type: ProtocolViewType, delegate: ProtocolSwitchVCDelegate?, protocolName: String = "")
    case maintenanceLocation(isStaticIp: Bool)
    case protocolSwitchVC(delegate: ProtocolSwitchVCDelegate?, type: ProtocolFallbacksType)
}

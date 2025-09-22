//
//  SharedKeys.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-14.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

enum SharedKeys {
    static let privateKey = "DynamicWireguardPrivateKey"
    static let activeUserSessionAuth = "activeSessionAuthHash"
    static let sharedGroup = "group.\(SharedKeys.getValueFromPlistFile(key: "CFAPP_BUNDLE_ID"))"
    static let sharedKeychainGroup = "\(SharedKeys.getValueFromPlistFile(key: "CFAccountID")).\(SharedKeys.getValueFromPlistFile(key: "CFAPP_BUNDLE_ID"))"
    static let preSharedKey = "preSharedKey"
    static let allowedIp = "allowedIp"
    static let dns = "dns"
    static let address = "address"
    static let serverEndPoint = "serverEndPoint"
    static let serverHostName = "serverHostName"
    static let serverPublicKey = "serverPublicKey"
    static let port = "port"
    static let wgPort = "wgPort"
    static let countryOverride = "countryOverride"
    static let circumventCensorship = "circumventCensorship"
    static let advanceParams = "AdvanceParams"
    static let serverSettings = "ServerSettings"

    // UserPreferenceManager
    static let orderLocationsBy = "OrderLocationsBy"
    static let language = "language"
    static let firewall = "firewall"
    static let killSwitch = "killSwitch"
    static let allowLanMode = "allowLanMode"
    static let hapticFeedback = "hapticFeedback"
    static let selectedProtocol = "selectedProtocol"
    static let serverHealth = "serverHealth"
    static let darkMode = "darkMode"
    static let pingMethod = "pingMethod"
    static let connectedDNSValue = "connectedDNSValue"
    static let appSkinType = "appSkinType"

    // UserDefaultKeys
    static let autoSecureNewNetworks = "AutoSecureNewNetworks"
    static let connectionMode = "connection-mode"
    static let connectedDNS = "connected-DNS"
    static let connectionCount = "connection-count"
    static let lastConnectedNetworkName = "last-connected-network-name"
    static let rateUsPopupDisplayed = "rate-us-popup-displayed"
    static let rateUsPopupWasAttempted = "rate-us-popup-was-attempted"
    static let lastLoginDate = "last-login-date"
    static let rateUsActionCompleted = "rate-us-action-completed-native-dialog"
    static let rateUsPopupDisplayCount = "rate-us-popup-display-count"
    static let privacyPopupAccepted = "privacy-popup-accepted"
    static let shakeForDataHighestScore = "shake-for-data-highest-score"
    static let shakeForDataUnlock = "shake-for-data-unlock"
    static let firstInstall = "first-install"
    static let registeredForPushNotifications = "registered-for-push-notifications"
    static let blurStaticIpAddress = "blur-static-ip-address"
    static let blurNetworkName = "blur-network-name"
    static let wireguardWakeupTime = "wireguard-wake-up-time"

    static let activeSessionAuthHash = "activeSessionAuthHash"
    static let notificationRetriavalTimestamp = "notificationRetriavalTimestamp"

    static let activeAppleID = "active-apple-id"
    static let activeAppleData = "active-apple-data"
    static let activeAppleSig = "active-apple-sig"
    static let activeManagerKey = "activeManager"
    static let selectedLanguage = "selectedLanguage"
    static let defaultLanguage = "defaultLanguage"
    static let appleLanguage = "AppleLanguages"

    // Widget GroupPersistenceManager keys
    static let serverNameKey = "server-name"
    static let countryCodeKey = "country-code"
    static let nickNameKey = "nick-name"
    static let serverCredentialsTypeKey = "server-credentials"
    static let forceDisconnect = "force-disconnect"
    static let widgetConnectionRequested = "widget-connection-requested"

    // language manager
    static let languageManagerSelectedLanguage = "LanguageManagerSelectedLanguage"
    static let languageManagerDefaultLanguage = "LanguageManagerDefaultLanguage"

    // ReferAndShareManager
    static let referAndShareUserDefautsKeys = "referAndShareUserDefautsKeys"
    static let tvFavourites = "tvfavourites"

    // Locations
    static let savedLastLocation = "savedLastLocation"
    static let savedBestLocation = "savedBestLocation"

    // Aspect Ratio
    static let aspectRatio = "aspectRatio"

    // Sounds
    static let connectSoundEffect = "connectSoundEffect"
    static let disconnectSoundEffect = "disconnectSoundEffect"
    static let customSoundEffectPathConnect = "customSoundEffectPathConnect"
    static let customSoundEffectPathDisconnect = "customSoundEffectPathDisconnect"

    // Backgrounds
    static let connectBackgroundEffect = "connectBackgroundEffect"
    static let disconnectBackgroundEffect = "disconnectBackgroundEffect"
    static let connectBackgroundCustomPath = "connectBackgroundCustomPath"
    static let disconnectBackgroundCustomPath = "disconnectBackgroundCustomPath"

    // Custom Locations Names
    static let customLocationNames = "customLocationNames"

    /// Cached plist dictionary to avoid repeated file I/O
    private static let plistDictionary: [String: Any] = {
        guard let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: plistPath),
              let dictionary = try? PropertyListSerialization.propertyList(
                from: plistData, options: [], format: nil) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }()

    /// Read value from plist file or not found returns empty string.
    private static func getValueFromPlistFile(key: String) -> String {
        return plistDictionary[key] as? String ?? ""
    }
}

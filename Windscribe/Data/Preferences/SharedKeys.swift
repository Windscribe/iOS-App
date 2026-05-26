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
    static let appBundleID = SharedKeys.getValueFromPlistFile(key: "CFAPP_BUNDLE_ID")
    static let sharedGroup = "group.\(appBundleID)"
    static let sharedKeychainGroup = "\(SharedKeys.getValueFromPlistFile(key: "CFAccountID")).\(appBundleID)"
    static let preSharedKey = "preSharedKey"
    static let allowedIp = "allowedIp"
    static let allowedIpV6 = "allowedIpV6"
    static let hashedCIDR = "hashedCIDR"
    static let hashedCIDRv6 = "hashedCIDRv6"
    static let dns = "dns"
    static let address = "address"
    static let addressV6 = "addressV6"
    static let serverSupportsIPv6 = "serverSupportsIPv6"
    static let serverEndPoint = "serverEndPoint"
    static let serverHostName = "serverHostName"
    static let serverPublicKey = "serverPublicKey"
    static let port = "port"
    static let wgPort = "wgPort"
    static let countryOverride = "countryOverride"
    static let circumventCensorship = "circumventCensorship"
    static let advanceParams = "AdvanceParams"
    static let serverSettings = "ServerSettings"
    static let lasUsedNodeIP = "LastUsedNodeIP"
    static let ignorePinIP = "IgnorePinIP"

    // UserPreferenceManager
    static let orderLocationsBy = "OrderLocationsBy"
    static let language = "language"
    static let firewall = "firewall"
    static let killSwitch = "killSwitch"
    static let allowLanMode = "allowLanMode"
    static let hapticFeedback = "hapticFeedback"
    static let selectedProtocol = "selectedProtocol"
    static let serverNetLoad = "serverHealth"
    static let darkMode = "darkMode"
    static let connectedDNSValue = "connectedDNSValue"

    // UserDefaultKeys
    static let autoSecureNewNetworks = "AutoSecureNewNetworks"
    static let connectionMode = "connection-mode"
    static let connectedDNS = "connected-DNS"
    static let connectionCount = "connection-count"
    static let rateUsPopupDisplayed = "rate-us-popup-displayed"
    static let rateUsPopupWasAttempted = "rate-us-popup-was-attempted"
    static let lastLoginDate = "last-login-date"
    static let rateUsActionCompleted = "rate-us-action-completed-native-dialog"
    static let rateUsPopupDisplayCount = "rate-us-popup-display-count"
    static let privacyPopupAccepted = "privacy-popup-accepted"
    static let shakeForDataHighestScore = "shake-for-data-highest-score"
    static let firstInstall = "first-install"
    static let registeredForPushNotifications = "registered-for-push-notifications"
    static let blurStaticIpAddress = "blur-static-ip-address"
    static let blurNetworkName = "blur-network-name"
    static let wireguardWakeupTime = "wireguard-wake-up-time"

    static let activeSessionAuthHash = "activeSessionAuthHash"
    static let notificationRetriavalTimestamp = "notificationRetriavalTimestamp"
    static let lastUpdatePromptTimestamp = "lastUpdatePromptTimestamp"
    static let lastUpdateCheckTimestamp = "lastUpdateCheckTimestamp"
    static let tunnelStoppedForAppUpdate = "tunnelStoppedForAppUpdate"

    static let activeAppleID = "active-apple-id"
    static let activeAppleData = "active-apple-data"
    static let activeAppleSig = "active-apple-sig"
    static let activeManagerKey = "activeManager"
    static let selectedLanguage = "selectedLanguage"
    static let defaultLanguage = "defaultLanguage"
    static let appleLanguage = "AppleLanguages"
    static let ssoProvider = "ssoProvider"

    // Widget GroupPersistenceManager keys
    static let serverNameKey = "server-name"
    static let countryCodeKey = "country-code"
    static let nickNameKey = "nick-name"
    static let serverCredentialsTypeKey = "server-credentials"
    static let disconnectReason = "disconnect-reason"
    static let userStatus = "user-status"

    // IP Address - Issue #911
    static let currentIpAddress = "current-ip-address"

    // language manager
    static let languageManagerSelectedLanguage = "LanguageManagerSelectedLanguage"

    // ReferAndShareManager
    static let referAndShareUserDefautsKeys = "referAndShareUserDefautsKeys"
    static let tvFavourites = "tvfavourites"

    // Locations
    static let savedLastPinnedIP = "savedLastPinnedIP"
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

    // Custom App Icon
    static let customAppIcon = "customAppIcon"

    // IP Stack
    static let ipStackEgressKey = "ipStackEgress"
    static let ipStackIngressKey = "ipStackIngress"

    // Unblock WG Params
    static let unblockWgParams = "unblockWgParams"

    // Locations and Servers revision
    static let serverRevision = "serverRevision"
    static let routingType = "routingType"

    // Realm → GRDB one-time migration flag. Bumped to _v2 with #1074 to force re-migration from canonical Realm.
    static let didMigrateRealmToGRDB = "didMigrateRealmToGRDB_v2"

    // MARK: - Keychain Keys
    static let keychainOpenVPNCred = "openvpn-server-cred"
    static let keychainIKEv2Cred = "ikev2-server-cred"
    static let keychainStoredSession = "stored-session-data"
    static let keychainCustomConfigCreds = "customconfig-credentials"


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

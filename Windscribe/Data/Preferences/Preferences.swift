//
//  Preferences.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-14.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol Preferences {
    func saveAdvanceParams(params: String)
    func getAdvanceParams() -> AnyPublisher<String?, Never>
    func getAdvanceParams() -> String?
    func saveUserSessionAuth(sessionAuth: String?)
    func userSessionAuth() -> String?

    // UserPreferenceManager
    func saveOrderLocationsBy(order: String)
    func getOrderLocationsBy() -> AnyPublisher<String?, Never>
    func saveLanguage(language: String)
    func getLanguage() -> AnyPublisher<String?, Never>
    func saveFirewallMode(firewall: Bool)
    func getFirewallMode() -> AnyPublisher<Bool?, Never>
    func saveKillSwitch(killSwitch: Bool)
    func getKillSwitch() -> AnyPublisher<Bool?, Never>
    func getKillSwitchSync() -> Bool
    func saveAllowLane(mode: Bool)
    func getAllowLaneSync() -> Bool
    func getAllowLAN() -> AnyPublisher<Bool?, Never>
    func saveHapticFeedback(haptic: Bool)
    func getHapticFeedback() -> AnyPublisher<Bool?, Never>
    func saveSelectedProtocol(selectedProtocol: String)
    func getSelectedProtocol() -> AnyPublisher<String?, Never>
    func saveSelectedPort(port: String)
    func getSelectedPort() -> AnyPublisher<String?, Never>
    func saveDarkMode(darkMode: Bool)
    func getDarkMode() -> AnyPublisher<Bool?, Never>
    func saveShowServerHealth(show: Bool)
    func getShowServerHealth() -> AnyPublisher<Bool?, Never>
    func savePingMethod(method: String)
    func getPingMethod() -> AnyPublisher<String?, Never>
    func getPingMethodSync() -> String

    // PersistenceManager+UserDefaults
    func getConnectionCount() -> Int?
    func increaseConnectionCount()
    func saveConnectionCount(count: Int)
    func getLastConnectedNetworkName() -> String?
    func saveLastConnectedNetworkName(network: String)
    func getRateUsActionCompleted() -> Bool
    func saveRateUsActionCompleted(bool: Bool)
    func getWhenRateUsPopupDisplayed() -> Date?
    func saveWhenRateUsPopupDisplayed(date: Date)
    func getNativeRateUsPopupDisplayCount() -> Int?
    func saveNativeRateUsPopupDisplayCount(count: Int)
    func getPrivacyPopupAccepted() -> Bool?
    func savePrivacyPopupAccepted(bool: Bool)
    func getShakeForDataHighestScore() -> Int?
    func saveShakeForDataHighestScore(score: Int)
    func getUnlockShakeForData() -> Bool?
    func saveUnlockShakeForData(bool: Bool?)

    func saveBlurStaticIpAddress(bool: Bool?)
    func getBlurStaticIpAddress() -> Bool?
    func saveBlurNetworkName(bool: Bool?)
    func getBlurNetworkName() -> Bool?
    func saveSelectedLanguage(language: String?)
    func getSelectedLanguage() -> String?
    func saveDefaultLanguage(language: String?)
    func getDefaultLanguage() -> String?
    func saveActiveManagerKey(key: String?)
    func getActiveManagerKey() -> String?
    func saveRegisteredForPushNotifications(bool: Bool?)
    func getRegisteredForPushNotifications() -> Bool?
    func saveFirstInstall(bool: Bool?)
    func getFirstInstall() -> Bool?
    func saveActiveAppleSig(sig: String?)
    func getActiveAppleSig() -> String?
    func saveActiveAppleData(data: String?)
    func getActiveAppleData() -> String?
    func saveActiveAppleID(id: String?)
    func getActiveAppleID() -> String?
    func saveAppleLanguage(languge: String?)
    func getAppleLanguage() -> String?
    func saveLastNotificationTimestamp(timeStamp: Double?)
    func getLastNotificationTimestamp() -> Double?
    func saveSessionAuthHash(sessionAuth: String)
    func getSessionAuthHash() -> String?
    func saveCountryOverrride(value: String?)
    func getCountryOverride() -> String?
    func getLanguageManagerLanguage() -> String?

    func saveServerNameKey(key: String?)
    func getServerNameKey() -> String?
    func saveCountryCodeKey(key: String?)
    func getcountryCodeKey() -> String?
    func saveNickNameKey(key: String?)
    func getNickNameKey() -> String?
    func getCircumventCensorshipEnabled() -> AnyPublisher<Bool, Never>
    func isCircumventCensorshipEnabled() -> Bool
    func saveCircumventCensorshipStatus(status: Bool)

    func setLanguageManagerSelectedLanguage(language: Languages)
    func setLanguageManagerDefaultLanguage(language: String)
    func getLanguageManagerDefaultLanguage() -> String?
    func getLanguageManagerSelectedLanguage() -> AnyPublisher<String?, Never>

    func getServerCredentialTypeKey() -> String?

    func setServerCredentialTypeKey(typeKey: String)

    func getAutoSecureNewNetworks() -> AnyPublisher<Bool?, Never>
    func saveAutoSecureNewNetworks(autoSecure: Bool)

    func getConnectionMode() -> AnyPublisher<String?, Never>
    func getConnectedDNSObservable() -> AnyPublisher<String?, Never>
    func getConnectedDNS() -> String
    func saveConnectionMode(mode: String)
    func saveConnectedDNS(mode: String)

    func saveShowedShareDialog(showed: Bool)
    func getShowedShareDialog() -> Bool
    func getConnectionModeSync() -> String
    func getSelectedProtocolSync() -> String
    func getSelectedPortSync() -> String
    func getServerSettings() -> String
    func saveServerSettings(settings: String)

    func saveCustomDNSValue(value: DNSValue)
    func getCustomDNSValue() -> DNSValue
    func saveWireguardWakeupTime(value: Double)
    func getWireguardWakeupTime() -> Double
    func saveForceDisconnect(value: Bool)
    func getForceDisconnect() -> AnyPublisher<Bool?, Never>
    func observeFavouriteIds() -> AnyPublisher<[String], Never>
    func addFavouriteId(_ id: String)
    func removeFavouriteId(_ id: String)
    func clearFavourites()

    func getLoginDate() -> Date?
    func saveLoginDate(date: Date)

    // Widget Info
    func saveConnectionRequested(value: Bool)
    func getConnectionRequested() -> Bool

    // Locations
    func clearSelectedLocations()
    func saveLastSelectedLocation(with locationID: String)
    func getLastSelectedLocation() -> String
    func saveBestLocation(with locationID: String)
    func getBestLocation() -> String
    func isCustomConfigSelected() -> Bool
    func getLocationType() -> LocationType?
    func getLocationType(id: String) -> LocationType?

    // AspectRatio
    func saveAspectRatio(value: String)
    func getAspectRatio() -> String?
    func aspectRatio() -> AnyPublisher<String?, Never>

    // Backgrounds
    func saveBackgroundEffectConnect(value: String)
    func getBackgroundEffectConnect() -> String?
    func saveBackgroundCustomConnectPath(value: String)
    func getBackgroundCustomConnectPath() -> String?

    func saveBackgroundEffectDisconnect(value: String)
    func getBackgroundEffectDisconnect() -> String?
    func saveBackgroundCustomDisconnectPath(value: String)
    func getBackgroundCustomDisconnectPath() -> String?

    // Sounds
    func saveSoundEffectConnect(value: String)
    func getSoundEffectConnect() -> String?

    func saveSoundEffectDisconnect(value: String)
    func getSoundEffectDisconnect() -> String?

    func saveCustomSoundEffectPathConnect(_ path: String)
    func saveCustomSoundEffectPathDisconnect(_ path: String)
    func getCustomSoundEffectPathConnect() -> String?
    func getCustomSoundEffectPathDisconnect() -> String?

    // Custom Locations Names {
    func saveCustomLocationsNames(value: [ExportedRegion])
    func getCustomLocationsNames() -> [ExportedRegion]

    // WireGuard Interface Configuration
    func saveWireGuardAddress(_ address: String?)
    func getWireGuardAddress() -> String?
    func saveWireGuardDNS(_ dns: String?)
    func getWireGuardDNS() -> String?

    // WireGuard Peer Configuration
    func saveWireGuardPresharedKey(_ key: String?)
    func getWireGuardPresharedKey() -> String?
    func saveWireGuardAllowedIPs(_ ips: String?)
    func getWireGuardAllowedIPs() -> String?

    // WireGuard Server Configuration
    func saveWireGuardServerEndpoint(_ endpoint: String?)
    func getWireGuardServerEndpoint() -> String?
    func saveWireGuardServerHostname(_ hostname: String?)
    func getWireGuardServerHostname() -> String?
    func saveWireGuardServerPublicKey(_ key: String?)
    func getWireGuardServerPublicKey() -> String?
    func saveWireGuardServerPort(_ port: String?)
    func getWireGuardServerPort() -> String?

    // WireGuard Cleanup
    func clearWireGuardConfiguration()
}

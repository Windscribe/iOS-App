//
//  Preferences.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-14.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol Preferences: Sendable {
    func saveAdvanceParams(params: String)
    func getAdvanceParams() -> AnyPublisher<String?, Never>
    func getAdvanceParams() -> String?

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
    func getHapticFeedbackSync() -> Bool
    func saveSelectedProtocol(selectedProtocol: String)
    func getSelectedProtocol() -> AnyPublisher<String?, Never>
    func saveSelectedPort(port: String)
    func getSelectedPort() -> AnyPublisher<String?, Never>
    func saveDarkMode(darkMode: Bool)
    func getDarkMode() -> AnyPublisher<Bool?, Never>
    func saveShowServerNetLoad(show: Bool)
    func getShowServerNetLoad() -> AnyPublisher<Bool?, Never>
    func getShowServerNetLoadSync() -> Bool
    func saveEgressProtocolPreference(value: String)
    func getEgressProtocolPreference() -> AnyPublisher<String?, Never>
    func getEgressProtocolPreferenceSync() -> String
    func saveIngressProtocolPreference(value: String)
    func getIngressProtocolPreference() -> AnyPublisher<String?, Never>
    func getIngressProtocolPreferenceSync() -> String

    // PersistenceManager+UserDefaults
    func getConnectionCount() -> Int?
    func increaseConnectionCount()
    func saveConnectionCount(count: Int)
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

    func saveBlurStaticIpAddress(bool: Bool?)
    func getBlurStaticIpAddress() -> Bool?
    func saveBlurNetworkName(bool: Bool?)
    func getBlurNetworkName() -> Bool?
    func getSelectedLanguage() -> String?
    func saveDefaultLanguage(language: String?)
    func getDefaultLanguage() -> String?
    func saveActiveManagerKey(key: String?)
    func getActiveManagerKey() -> String?
    func saveRegisteredForPushNotifications(bool: Bool?)
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
    func saveLastUpdatePromptTimestamp(timeStamp: Double?)
    func getLastUpdatePromptTimestamp() -> Double?
    func saveLastUpdateCheckTimestamp(timeStamp: Double?)
    func getLastUpdateCheckTimestamp() -> Double?
    func saveTunnelStoppedForAppUpdate(status: Bool)
    func getTunnelStoppedForAppUpdate() -> Bool
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
    func getLanguageManagerSelectedLanguage() -> AnyPublisher<String?, Never>


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
    func observeFavouriteIds() -> AnyPublisher<[String], Never>
    func addFavouriteId(_ id: String)
    func removeFavouriteId(_ id: String)
    func saveDisconnectReason(reason: DisconnectReason)
    func getDisconnectReason() -> DisconnectReason
    func saveUserStatus(value: Bool)
    func getUserStatus() -> Bool
    func clearFavourites()

    func getLoginDate() -> Date?
    func saveLoginDate(date: Date)

    // Widget Info

    // IP Address - Issue #911
    func saveCurrentIpAddress(ip: String?)
    func getCurrentIpAddress() -> String?
    func getCurrentIpAddressObservable() -> AnyPublisher<String?, Never>

    // Locations
    func clearSelectedLocations()
    func saveLastConnectionTarget(with targetId: String)
    func getLastConnectionTarget() -> String
    func saveLastSelectedPinnedIp(with pinnedIP: String)
    func getLastSelectedPinnedIp() -> String?
    func saveBestLocation(with datacenterId: String)
    func getBestLocation() -> String
    func isCustomConfigSelected() -> Bool
    func getConnectionTargetType() -> ConnectionTargetType?
    func getConnectionTargetType(id: String) -> ConnectionTargetType?
    func saveLastNodeIP(nodeIp: String)
    func getLastNodeIP() -> String?
    func saveIgnorePinIP(status: Bool)
    func getIgnorePinIP() -> Bool

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

    // Custom App Icon
    func saveCustomAppIcon(value: String)
    func getCustomAppIcon() -> String?

    // Custom Locations Names {
    func saveCustomLocationsNames(value: [ExportedRegion])
    func getCustomLocationsNames() -> [ExportedRegion]

    // WireGuard Interface Configuration
    func saveWireGuardAddress(_ address: String?)
    func getWireGuardAddress() -> String?
    func saveWireGuardAddressV6(_ address: String?)
    func getWireGuardAddressV6() -> String?
    func saveWireGuardDNS(_ dns: String?)
    func getWireGuardDNS() -> String?

    // WireGuard Peer Configuration
    func saveWireGuardPresharedKey(_ key: String?)
    func getWireGuardPresharedKey() -> String?
    func saveWireGuardAllowedIPs(_ ips: String?)
    func getWireGuardAllowedIPs() -> String?
    func saveWireGuardAllowedIPsV6(_ ips: String?)
    func getWireGuardAllowedIPsV6() -> String?
    func saveWireGuardHashedCIDR(_ cidr: [String]?)
    func getWireGuardHashedCIDR() -> [String]?
    func saveWireGuardHashedCIDRv6(_ cidr: [String]?)
    func getWireGuardHashedCIDRv6() -> [String]?

    func saveWireGuardServerSupportsIPv6(_ supports: Bool)
    func getWireGuardServerSupportsIPv6() -> Bool

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

    // Synchronous getters for tvOS preferences display
    func getOrderLocationsBySync() -> String?
    func getSelectedProtocolSync() -> String?
    func getSelectedPortSync() -> String?

    // Custom Config Credentials (Keychain-backed)
    func getAllCustomConfigCredentials() -> [String: ServerCredentialsModel]
    func saveAllCustomConfigCredentials(_ credentials: [String: ServerCredentialsModel])
    func saveCustomConfigCredentials(configId: String, credentials: ServerCredentialsModel)
    func getCustomConfigCredentials(configId: String) -> ServerCredentialsModel?
    func deleteCustomConfigCredentials(configId: String)
    func deleteAllCustomConfigCredentials()

    // OpenVPN Server Credentials (Keychain-backed)
    func saveOpenVPNCredentials(_ credentials: ServerCredentialsModel)
    func getOpenVPNCredentials() -> ServerCredentialsModel?
    func deleteOpenVPNCredentials()

    // IKEv2 Server Credentials (Keychain-backed)
    func saveIKEv2Credentials(_ credentials: ServerCredentialsModel)
    func getIKEv2Credentials() -> ServerCredentialsModel?
    func deleteIKEv2Credentials()

    // Session Persistence (Keychain-backed)
    func saveStoredSession(_ data: Data) throws
    func getStoredSession() throws -> Data?
    func deleteStoredSession()

    // SSO Provider Tracking
    func saveSSOProvider(provider: String?)
    func getSSOProvider() -> String?

    // Unblock WG Params
    func saveUnblockWgParams(param: UnblockWgParams)
    func getUnblockWgParams() -> UnblockWgParams?

    // Locations and Servers revision
    func saveServerRevision(revision: Int64)
    func getServerRevision() -> Int64
    func saveRoutingType(routingType: ServerRoutingType)
    func getRoutingType() -> ServerRoutingType

    // Realm → GRDB one-time migration flag
    func didMigrateRealmToGRDB() -> Bool
    func saveDidMigrateRealmToGRDB(_ value: Bool)

    // Session Auth
    func clearUserDefaultsSessionAuth()
    func getUserDefaultsSessionAuth() -> String?
    func clearSessionAuth()
    func saveSessionAuthHash(sessionAuth: String)
    func getSessionAuthHash() -> String?
}

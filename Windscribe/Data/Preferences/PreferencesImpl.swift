//
//  SharedUserDefaults.swift
//  Windscribe
//
//  Created by Ginder Singh on 2022-03-18.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

enum ConnectionTargetType {
    case server
    case staticIP
    case custom
}

class PreferencesImpl: Preferences {
    let sharedDefault: UserDefaults?
    let logger: FileLogger
    let keychainManager: KeychainManager

    init(logger: FileLogger, keychainManager: KeychainManager) {
        self.logger = logger
        self.keychainManager = keychainManager
        self.sharedDefault = UserDefaults(suiteName: SharedKeys.sharedGroup)
    }

    func saveShowedShareDialog(showed: Bool = true) {
        setBool(showed, forKey: SharedKeys.referAndShareUserDefautsKeys)
    }

    func getShowedShareDialog() -> Bool {
        return getBool(key: SharedKeys.referAndShareUserDefautsKeys)
    }

    func setServerCredentialTypeKey(typeKey: String) {
        setString(typeKey, forKey: SharedKeys.serverCredentialsTypeKey)
    }

    func setLanguageManagerSelectedLanguage(language: Languages) {
        setString(language.name, forKey: SharedKeys.languageManagerSelectedLanguage)
    }

    func getLanguageManagerSelectedLanguage() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.languageManagerSelectedLanguage, type: String.self, defaultValue: Languages.english.name)
    }

    func getLanguageManagerLanguage() -> String? {
        return getString(forKey: SharedKeys.languageManagerSelectedLanguage)
    }

    func saveServerNameKey(key: String?) {
        setString(key, forKey: SharedKeys.serverNameKey)
    }

    func getServerNameKey() -> String? {
        return getString(forKey: SharedKeys.serverNameKey)
    }

    func saveCountryCodeKey(key: String?) {
        setString(key, forKey: SharedKeys.countryCodeKey)
    }

    func getcountryCodeKey() -> String? {
        return getString(forKey: SharedKeys.countryCodeKey)
    }

    func saveNickNameKey(key: String?) {
        setString(key, forKey: SharedKeys.nickNameKey)
    }

    func getNickNameKey() -> String? {
        return getString(forKey: SharedKeys.nickNameKey)
    }

    func saveConnectionMode(mode: String) {
        setString(mode, forKey: SharedKeys.connectionMode)
    }

    func saveConnectedDNS(mode: String) {
        setString(mode, forKey: SharedKeys.connectedDNS)
    }

    func getConnectionMode() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.connectionMode, type: String.self, defaultValue: DefaultValues.connectionMode)
    }

    func getConnectionModeSync() -> String {
        return sharedDefault?.string(forKey: SharedKeys.connectionMode) ?? DefaultValues.connectionMode
    }

    func getConnectedDNS() -> String {
        return getString(forKey: SharedKeys.connectedDNS) ?? DefaultValues.connectedDNS
    }

    func getConnectedDNSObservable() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.connectedDNS, type: String.self, defaultValue: DefaultValues.connectedDNS)
    }

    func saveAutoSecureNewNetworks(autoSecure: Bool) {
        setBool(autoSecure, forKey: SharedKeys.autoSecureNewNetworks)
    }

    func getAutoSecureNewNetworks() -> AnyPublisher<Bool?, Never> {
        return observeKey(SharedKeys.autoSecureNewNetworks, type: Bool.self, defaultValue: DefaultValues.autoSecureNewNetworks)
    }

    func saveBlurStaticIpAddress(bool: Bool?) {
        setBool(bool, forKey: SharedKeys.blurStaticIpAddress)
    }

    func getBlurStaticIpAddress() -> Bool? {
        return getBool(key: SharedKeys.blurStaticIpAddress)
    }

    func saveBlurNetworkName(bool: Bool?) {
        setBool(bool, forKey: SharedKeys.blurNetworkName)
    }

    func getBlurNetworkName() -> Bool? {
        return getBool(key: SharedKeys.blurNetworkName)
    }

    func getSelectedLanguage() -> String? {
        return getString(forKey: SharedKeys.selectedLanguage)
    }

    func saveDefaultLanguage(language: String?) {
        setString(language, forKey: SharedKeys.defaultLanguage)
    }

    func getDefaultLanguage() -> String? {
        return getString(forKey: SharedKeys.defaultLanguage)
    }

    func saveActiveManagerKey(key: String?) {
        setString(key, forKey: SharedKeys.activeManagerKey)
    }

    func getActiveManagerKey() -> String? {
        return getString(forKey: SharedKeys.activeManagerKey)
    }

    func saveRegisteredForPushNotifications(bool: Bool?) {
        setBool(bool, forKey: SharedKeys.registeredForPushNotifications)
    }

    func saveFirstInstall(bool: Bool?) {
        setBool(bool, forKey: SharedKeys.firstInstall)
    }

    func getFirstInstall() -> Bool? {
        return getBool(key: SharedKeys.firstInstall)
    }

    func saveActiveAppleSig(sig: String?) {
        setString(sig, forKey: SharedKeys.activeAppleSig)
    }

    func getActiveAppleSig() -> String? {
        return getString(forKey: SharedKeys.activeAppleSig)
    }

    func saveActiveAppleData(data: String?) {
        setString(data, forKey: SharedKeys.activeAppleData)
    }

    func getActiveAppleData() -> String? {
        return getString(forKey: SharedKeys.activeAppleData)
    }

    func saveActiveAppleID(id: String?) {
        setString(id, forKey: SharedKeys.activeAppleID)
    }

    func getActiveAppleID() -> String? {
        return getString(forKey: SharedKeys.activeAppleID)
    }

    func saveAppleLanguage(languge: String?) {
        setString(languge, forKey: SharedKeys.appleLanguage)
    }

    func getAppleLanguage() -> String? {
        return getString(forKey: SharedKeys.appleLanguage)
    }

    func saveLastNotificationTimestamp(timeStamp: Double?) {
        setDouble(timeStamp, forKey: SharedKeys.notificationRetriavalTimestamp)
    }

    func getLastNotificationTimestamp() -> Double? {
        return getDouble(forKey: SharedKeys.notificationRetriavalTimestamp)
    }

    func saveLastUpdatePromptTimestamp(timeStamp: Double?) {
        setDouble(timeStamp, forKey: SharedKeys.lastUpdatePromptTimestamp)
    }

    func getLastUpdatePromptTimestamp() -> Double? {
        return getDouble(forKey: SharedKeys.lastUpdatePromptTimestamp)
    }

    func saveLastUpdateCheckTimestamp(timeStamp: Double?) {
        setDouble(timeStamp, forKey: SharedKeys.lastUpdateCheckTimestamp)
    }

    func getLastUpdateCheckTimestamp() -> Double? {
        return getDouble(forKey: SharedKeys.lastUpdateCheckTimestamp)
    }

    func saveTunnelStoppedForAppUpdate(status: Bool) {
        setBool(status, forKey: SharedKeys.tunnelStoppedForAppUpdate)
    }

    func getTunnelStoppedForAppUpdate() -> Bool {
        return getBool(key: SharedKeys.tunnelStoppedForAppUpdate)
    }

    func getConnectionCount() -> Int? {
        return getInt(forKey: SharedKeys.connectionCount)
    }

    func increaseConnectionCount() {
        let currentCount = getConnectionCount() ?? 0
        setInt(currentCount + 1, forKey: SharedKeys.connectionCount)
    }

    func saveConnectionCount(count: Int) {
        setInt(count, forKey: SharedKeys.connectionCount)
    }

    func getRateUsActionCompleted() -> Bool {
        return getBool(key: SharedKeys.rateUsActionCompleted)
    }

    func saveRateUsActionCompleted(bool: Bool) {
        setBool(bool, forKey: SharedKeys.rateUsActionCompleted)
    }

    func getWhenRateUsPopupDisplayed() -> Date? {
        return getDate(forKey: SharedKeys.rateUsPopupDisplayed)
    }

    func saveWhenRateUsPopupDisplayed(date: Date) {
        setDate(date, forKey: SharedKeys.rateUsPopupDisplayed)
    }

    func getLoginDate() -> Date? {
        return getDate(forKey: SharedKeys.lastLoginDate)
    }

    func saveLoginDate(date: Date) {
        setDate(date, forKey: SharedKeys.lastLoginDate)
    }

    func getNativeRateUsPopupDisplayCount() -> Int? {
        return getInt(forKey: SharedKeys.rateUsPopupDisplayCount)
    }

    func saveNativeRateUsPopupDisplayCount(count: Int) {
        setInt(count, forKey: SharedKeys.rateUsPopupDisplayCount)
    }

    func getPrivacyPopupAccepted() -> Bool? {
        return getBool(key: SharedKeys.privacyPopupAccepted)
    }

    func savePrivacyPopupAccepted(bool: Bool) {
        setBool(bool, forKey: SharedKeys.privacyPopupAccepted)
    }

    func getShakeForDataHighestScore() -> Int? {
        return getInt(forKey: SharedKeys.shakeForDataHighestScore)
    }

    func saveShakeForDataHighestScore(score: Int) {
        setInt(score, forKey: SharedKeys.shakeForDataHighestScore)
    }

    func saveOrderLocationsBy(order: String) {
        setString(order, forKey: SharedKeys.orderLocationsBy)
    }

    func getOrderLocationsBy() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.orderLocationsBy, type: String.self, defaultValue: DefaultValues.orderLocationsBy)
    }

    func saveLanguage(language: String) {
        setString(language, forKey: SharedKeys.language)
    }

    func getLanguage() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.language, type: String.self, defaultValue: DefaultValues.language)
    }

    func saveFirewallMode(firewall: Bool) {
        setBool(firewall, forKey: SharedKeys.firewall)
    }

    func getFirewallMode() -> AnyPublisher<Bool?, Never> {
        return observeKey(SharedKeys.firewall, type: Bool.self, defaultValue: DefaultValues.firewallMode)
    }

    func saveKillSwitch(killSwitch: Bool) {
        setBool(killSwitch, forKey: SharedKeys.killSwitch)
    }

    func getKillSwitch() -> AnyPublisher<Bool?, Never> {
        return observeKey(SharedKeys.killSwitch, type: Bool.self, defaultValue: DefaultValues.killSwitch)
    }

    func getKillSwitchSync() -> Bool {
        return sharedDefault?.bool(forKey: SharedKeys.killSwitch) ?? DefaultValues.killSwitch
    }

    func saveAllowLane(mode: Bool) {
        setBool(mode, forKey: SharedKeys.allowLanMode)
    }

    func getAllowLaneSync() -> Bool {
        return sharedDefault?.bool(forKey: SharedKeys.allowLanMode) ?? DefaultValues.allowLANMode
    }

    func getAllowLAN() -> AnyPublisher<Bool?, Never> {
        return observeKey(SharedKeys.allowLanMode, type: Bool.self, defaultValue: DefaultValues.allowLANMode)
    }

    func saveHapticFeedback(haptic: Bool) {
        setBool(haptic, forKey: SharedKeys.hapticFeedback)
    }

    func getHapticFeedback() -> AnyPublisher<Bool?, Never> {
        return observeKey(SharedKeys.hapticFeedback, type: Bool.self, defaultValue: DefaultValues.hapticFeedback)
    }

    func getHapticFeedbackSync() -> Bool {
        getBool(key: SharedKeys.hapticFeedback)
    }

    func saveCustomDNSValue(value: DNSValue) {
        saveObject(object: value, forKey: SharedKeys.connectedDNSValue)
    }

    func getCustomDNSValue() -> DNSValue {
        getObject(forKey: SharedKeys.connectedDNSValue) ?? DefaultValues.customDNSValue
    }

    func saveSelectedProtocol(selectedProtocol: String) {
        setString(selectedProtocol, forKey: SharedKeys.selectedProtocol)
    }

    func getSelectedProtocol() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.selectedProtocol, type: String.self, defaultValue: DefaultValues.protocol)
    }

    func getSelectedProtocolSync() -> String {
        return sharedDefault?.string(forKey: SharedKeys.selectedProtocol) ?? DefaultValues.protocol
    }

    func getSelectedPortSync() -> String {
        return sharedDefault?.string(forKey: SharedKeys.port) ?? DefaultValues.port
    }

    func saveSelectedPort(port: String) {
        setString(port, forKey: SharedKeys.port)
    }

    func getSelectedPort() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.port, type: String.self, defaultValue: DefaultValues.port)
    }

    func saveDarkMode(darkMode: Bool) {
        setBool(darkMode, forKey: SharedKeys.darkMode)
    }

    func getDarkMode() -> AnyPublisher<Bool?, Never> {
        return observeKey(SharedKeys.darkMode, type: Bool.self, defaultValue: DefaultValues.darkMode)
    }

    func saveShowServerNetLoad(show: Bool) {
        setBool(show, forKey: SharedKeys.serverNetLoad)
    }

    func getShowServerNetLoad() -> AnyPublisher<Bool?, Never> {
        return observeKey(SharedKeys.serverNetLoad, type: Bool.self, defaultValue: DefaultValues.showServerNetLoad)
    }

    func getShowServerNetLoadSync() -> Bool {
        getBool(key: SharedKeys.serverNetLoad)
    }

    func saveAdvanceParams(params: String) {
        setString(params, forKey: SharedKeys.advanceParams)
    }

    func getAdvanceParams() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.advanceParams, type: String.self)
    }

    func getAdvanceParams() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.advanceParams)
    }

    func saveCountryOverrride(value: String?) {
        setString(value, forKey: SharedKeys.countryOverride)
    }

    func getCountryOverride() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.countryOverride)
    }

    func saveCircumventCensorshipStatus(status: Bool) {
        setBool(status, forKey: SharedKeys.circumventCensorship)
    }

    func getCircumventCensorshipEnabled() -> AnyPublisher<Bool, Never> {
        return observeKeyNonOptional(SharedKeys.circumventCensorship, type: Bool.self, defaultValue: false) { $0 ?? false }
    }

    func isCircumventCensorshipEnabled() -> Bool {
        if let value = sharedDefault?.object(forKey: SharedKeys.circumventCensorship) as? Bool {
            return value
        }
        return false
    }

    func getServerSettings() -> String {
        return sharedDefault?.string(forKey: SharedKeys.serverSettings) ?? ""
    }

    func saveServerSettings(settings: String) {
        setString(settings, forKey: SharedKeys.serverSettings)
    }

    func getWireguardWakeupTime() -> Double {
        return sharedDefault?.double(forKey: SharedKeys.wireguardWakeupTime) ?? 0.0
    }

    func saveWireguardWakeupTime(value: Double) {
        sharedDefault?.set(value, forKey: SharedKeys.wireguardWakeupTime)
    }

    func saveSSOProvider(provider: String?) {
        setString(provider, forKey: SharedKeys.ssoProvider)
    }

    func getSSOProvider() -> String? {
        return getString(forKey: SharedKeys.ssoProvider)
    }

    func getDisconnectReason() -> DisconnectReason {
        let value = sharedDefault?.integer(forKey: SharedKeys.disconnectReason) ?? 0
        return DisconnectReason(rawValue: value) ?? .unknown
    }

    func saveDisconnectReason(reason: DisconnectReason) {
        setInt(reason.rawValue, forKey: SharedKeys.disconnectReason)
    }

    func getUserStatus() -> Bool {
        return sharedDefault?.bool(forKey: SharedKeys.userStatus) ?? false
    }

    func saveUserStatus(value: Bool) {
        setBool(value, forKey: SharedKeys.userStatus)
    }

    // MARK: - IP Address Storage - Issue #911
    func saveCurrentIpAddress(ip: String?) {
        setString(ip, forKey: SharedKeys.currentIpAddress)
    }

    func getCurrentIpAddress() -> String? {
        return getString(forKey: SharedKeys.currentIpAddress)
    }

    func getCurrentIpAddressObservable() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.currentIpAddress, type: String.self, defaultValue: nil)
    }

    func clearSelectedLocations() {
        sharedDefault?.set("", forKey: SharedKeys.savedLastLocation)
    }

    func saveLastConnectionTarget(with targetId: String) {
        sharedDefault?.set(targetId, forKey: SharedKeys.savedLastLocation)
    }

    func getLastConnectionTarget() -> String {
        return sharedDefault?.string(forKey: SharedKeys.savedLastLocation) ?? "0"
    }

    func saveLastSelectedPinnedIp(with pinnedIP: String) {
        sharedDefault?.set(pinnedIP, forKey: SharedKeys.savedLastPinnedIP)
    }

    func getLastSelectedPinnedIp() -> String? {
        let value = sharedDefault?.string(forKey: SharedKeys.savedLastPinnedIP)
        return value?.isEmpty == true ? nil : value
    }

    func saveBestLocation(with datacenterId: String) {
        sharedDefault?.set(datacenterId, forKey: SharedKeys.savedBestLocation)
    }

    func getBestLocation() -> String {
        return sharedDefault?.string(forKey: SharedKeys.savedBestLocation) ?? "0"
    }

    func isCustomConfigSelected() -> Bool {
        return getConnectionTargetType() == .custom
    }

    func getConnectionTargetType() -> ConnectionTargetType? {
        return getConnectionTargetType(id: getLastConnectionTarget())
    }

    /// Gets location type based on id.
    func getConnectionTargetType(id: String) -> ConnectionTargetType? {
        guard !id.isEmpty else { return nil }
        let parts = id.split(separator: "_")
        if parts.count == 1 {
            return ConnectionTargetType.server
        }
        let prefix = parts[0]
        if prefix == "static" {
            return ConnectionTargetType.staticIP
        } else if prefix == "custom" {
            return ConnectionTargetType.custom
        }
        return nil
    }

    func saveLastNodeIP(nodeIp: String) {
        sharedDefault?.set(nodeIp, forKey: SharedKeys.lasUsedNodeIP)
    }

    func getLastNodeIP() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.lasUsedNodeIP)
    }

    func saveIgnorePinIP(status: Bool) {
        sharedDefault?.set(status, forKey: SharedKeys.ignorePinIP)
    }

    func getIgnorePinIP() -> Bool {
        return sharedDefault?.bool(forKey: SharedKeys.ignorePinIP) ?? false
    }

    // MARK: - IP Stack
    func saveEgressProtocolPreference(value: String) {
        setString(value, forKey: SharedKeys.ipStackEgressKey)
    }

    func getEgressProtocolPreference() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.ipStackEgressKey, type: String.self, defaultValue: DefaultValues.ipStack)
    }

    func getEgressProtocolPreferenceSync() -> String {
        return sharedDefault?.string(forKey: SharedKeys.ipStackEgressKey) ?? DefaultValues.ipStack
    }

    func saveIngressProtocolPreference(value: String) {
        setString(value, forKey: SharedKeys.ipStackIngressKey)
    }

    func getIngressProtocolPreference() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.ipStackIngressKey, type: String.self, defaultValue: DefaultValues.ipStack)
    }

    func getIngressProtocolPreferenceSync() -> String {
        return sharedDefault?.string(forKey: SharedKeys.ipStackIngressKey) ?? DefaultValues.ipStack
    }

    // Unblock WG Params
    func saveUnblockWgParams(param: UnblockWgParams) {
        if let encoded = try? JSONEncoder().encode(param) {
            sharedDefault?.set(encoded, forKey: SharedKeys.unblockWgParams)
        }
    }

    func getUnblockWgParams() -> UnblockWgParams? {
        guard let data = sharedDefault?.data(forKey: SharedKeys.unblockWgParams) else {
            return nil
        }
        return try? JSONDecoder().decode(UnblockWgParams.self, from: data)
    }

    // Locations and Servers revision
    func saveServerRevision(revision: Int64) {
        setInt64(revision, forKey: SharedKeys.serverRevision)
    }

    func getServerRevision() -> Int64 {
        return getInt64(forKey: SharedKeys.serverRevision) ?? DefaultValues.revision
    }

    func saveRoutingType(routingType: ServerRoutingType) {
        setString(routingType.rawValue, forKey: SharedKeys.routingType)
    }

    func getRoutingType() -> ServerRoutingType {
        ServerRoutingType.init(rawValue: getString(forKey: SharedKeys.routingType) ?? "") ?? ServerRoutingType.auto
    }

    // MARK: - Realm → GRDB migration flag

    func didMigrateRealmToGRDB() -> Bool {
        return UserDefaults.standard.bool(forKey: SharedKeys.didMigrateRealmToGRDB)
    }

    func saveDidMigrateRealmToGRDB(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: SharedKeys.didMigrateRealmToGRDB)
    }
}

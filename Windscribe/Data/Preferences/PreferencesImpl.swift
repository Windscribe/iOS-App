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

enum LocationType {
    case server
    case staticIP
    case custom
}

class PreferencesImpl: Preferences {
    let sharedDefault: UserDefaults?

    init() {
        self.sharedDefault = UserDefaults(suiteName: SharedKeys.sharedGroup)
    }

    // MARK: - Generic Combine Helpers

    private func observeKey<T>(_ key: String, type: T.Type, defaultValue: T?) -> AnyPublisher<T?, Never> {
        guard let sharedDefault = sharedDefault else {
            return Just(defaultValue).eraseToAnyPublisher()
        }

        return sharedDefault.publisher(for: key, type: type)
            .map { $0 ?? defaultValue }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func observeKeyEmpty<T>(_ key: String, type: T.Type) -> AnyPublisher<T?, Never> {
        guard let sharedDefault = sharedDefault else {
            return Empty().eraseToAnyPublisher()
        }

        return sharedDefault.publisher(for: key, type: type)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func observeKeyNonOptional<T>(_ key: String, type: T.Type, defaultValue: T, transform: @escaping (T?) -> T) -> AnyPublisher<T, Never> {
        guard let sharedDefault = sharedDefault else {
            return Just(defaultValue).eraseToAnyPublisher()
        }

        return sharedDefault.publisher(for: key, type: type)
            .map(transform)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func saveShowedShareDialog(showed: Bool = true) {
        setBool(showed, forKey: SharedKeys.referAndShareUserDefautsKeys)
    }

    func getShowedShareDialog() -> Bool {
        return getBool(key: SharedKeys.referAndShareUserDefautsKeys)
    }

    func getServerCredentialTypeKey() -> String? {
        return getString(forKey: SharedKeys.serverCredentialsTypeKey)
    }

    func setServerCredentialTypeKey(typeKey: String) {
        setString(typeKey, forKey: SharedKeys.serverCredentialsTypeKey)
    }

    func setLanguageManagerSelectedLanguage(language: Languages) {
        setString(language.name, forKey: SharedKeys.languageManagerSelectedLanguage)
    }

    func getLanguageManagerSelectedLanguage() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.languageManagerSelectedLanguage, type: String.self, defaultValue: Languages.english.rawValue)
    }

    func getLanguageManagerLanguage() -> String? {
        return getString(forKey: SharedKeys.languageManagerSelectedLanguage)
    }

    func setLanguageManagerDefaultLanguage(language: String) {
        setString(language, forKey: SharedKeys.languageManagerDefaultLanguage)
    }

    func getLanguageManagerDefaultLanguage() -> String? {
        return getString(forKey: SharedKeys.languageManagerDefaultLanguage)
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

    func getConnectedDNS() -> String {
        return getString(forKey: SharedKeys.connectedDNS) ?? DefaultValues.connectedDNS
    }

    func getConnectedDNSObservable() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.connectedDNS, type: String.self, defaultValue: DefaultValues.connectedDNS)
    }

    func getConnectionModeSync() -> String {
        return sharedDefault?.string(forKey: SharedKeys.connectionMode) ?? DefaultValues.connectionMode
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

    func saveSelectedLanguage(language: String?) {
        setString(language, forKey: SharedKeys.selectedLanguage)
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

    func getRegisteredForPushNotifications() -> Bool? {
        return getBool(key: SharedKeys.registeredForPushNotifications)
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
        setString(id, forKey: SharedKeys.activeAppleData)
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

    func saveSessionAuthHash(sessionAuth: String) {
        setString(sessionAuth, forKey: SharedKeys.activeSessionAuthHash)
    }

    func getSessionAuthHash() -> String? {
        return getString(forKey: SharedKeys.activeSessionAuthHash)
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

    func getLastConnectedNetworkName() -> String? {
        return getString(forKey: SharedKeys.lastConnectedNetworkName)
    }

    func saveLastConnectedNetworkName(network: String) {
        setString(network, forKey: SharedKeys.lastConnectedNetworkName)
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

    func getUnlockShakeForData() -> Bool? {
        return getBool(key: SharedKeys.shakeForDataUnlock)
    }

    func saveUnlockShakeForData(bool: Bool?) {
        setBool(bool, forKey: SharedKeys.shakeForDataUnlock)
    }

    func saveOrderLocationsBy(order: String) {
        setString(order, forKey: SharedKeys.orderLocationsBy)
    }

    func getOrderLocationsBy() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.orderLocationsBy, type: String.self, defaultValue: DefaultValues.orderLocationsBy)
    }

    func saveAppSkinPreferences(type: String) {
        setString(type, forKey: SharedKeys.appSkinType)
    }

    func getAppSkinPreferences() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.appSkinType, type: String.self, defaultValue: DefaultValues.appSkin)
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

    func saveShowServerHealth(show: Bool) {
        setBool(show, forKey: SharedKeys.serverHealth)
    }

    func getShowServerHealth() -> AnyPublisher<Bool?, Never> {
        return observeKey(SharedKeys.serverHealth, type: Bool.self, defaultValue: DefaultValues.showServerHealth)
    }

    func savePingMethod(method: String) {
        setString(method, forKey: SharedKeys.pingMethod)
    }

    func getPingMethod() -> AnyPublisher<String?, Never> {
        return observeKey(SharedKeys.pingMethod, type: String.self, defaultValue: DefaultValues.pingMethod)
    }

    func getPingMethodSync() -> String {
        return sharedDefault?.string(forKey: SharedKeys.pingMethod) ?? DefaultValues.pingMethod
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

    func userSessionAuth() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.activeUserSessionAuth)
    }

    func saveUserSessionAuth(sessionAuth: String?) {
        setString(sessionAuth, forKey: SharedKeys.activeUserSessionAuth)
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
        return observeKeyNonOptional(SharedKeys.circumventCensorship, type: Bool.self, defaultValue: isRestrictedCountry()) { $0 ?? self.isRestrictedCountry() }
    }

    func isCircumventCensorshipEnabled() -> Bool {
        if let value = sharedDefault?.object(forKey: SharedKeys.circumventCensorship) as? Bool {
            return value
        }
        return isRestrictedCountry()
    }

    func isRestrictedCountry() -> Bool {
        let languageCode: String?

        if #available(iOS 16.0, *) {
            languageCode = Locale.current.language.languageCode?.identifier
        } else {
            languageCode = Locale.current.languageCode
        }

        return ["be", "fa", "ru", "tr", "zh"].contains(languageCode ?? "")
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

    func saveForceDisconnect(value: Bool) {
        setBool(value, forKey: SharedKeys.forceDisconnect)
    }

    func getForceDisconnect() -> AnyPublisher<Bool?, Never> {
        return observeKey(SharedKeys.forceDisconnect, type: Bool.self, defaultValue: false)
    }

    func saveConnectionRequested(value: Bool) {
        setBool(value, forKey: SharedKeys.widgetConnectionRequested)
    }

    func getConnectionRequested() -> Bool {
        return sharedDefault?.bool(forKey: SharedKeys.widgetConnectionRequested) ?? false
    }

    func clearSelectedLocations() {
        sharedDefault?.set("", forKey: SharedKeys.savedLastLocation)
    }

    func saveLastSelectedLocation(with locationID: String) {
        sharedDefault?.set(locationID, forKey: SharedKeys.savedLastLocation)
    }

    func getLastSelectedLocation() -> String {
        return sharedDefault?.string(forKey: SharedKeys.savedLastLocation) ?? "0"
    }

    func saveBestLocation(with locationID: String) {
        sharedDefault?.set(locationID, forKey: SharedKeys.savedBestLocation)
    }

    func getBestLocation() -> String {
        return sharedDefault?.string(forKey: SharedKeys.savedBestLocation) ?? "0"
    }

    func isCustomConfigSelected() -> Bool {
        return getLocationType() == .custom
    }

    func getLocationType() -> LocationType? {
        return getLocationType(id: getLastSelectedLocation())
    }

    /// Gets location type based on id.
    func getLocationType(id: String) -> LocationType? {
        guard !id.isEmpty else { return nil }
        let parts = id.split(separator: "_")
        if parts.count == 1 {
            return LocationType.server
        }
        let prefix = parts[0]
        if prefix == "static" {
            return LocationType.staticIP
        } else if prefix == "custom" {
            return LocationType.custom
        }
        return nil
    }

    // Aspect Ratio
    func saveAspectRatio(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.aspectRatio)
    }

    func getAspectRatio() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.aspectRatio)
    }

    func aspectRatio() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.aspectRatio, type: String.self)
    }

    // Sounds
    func saveSoundEffectConnect(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.connectSoundEffect)
    }

    func getSoundEffectConnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.connectSoundEffect)
    }

    func saveSoundEffectDisconnect(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.disconnectSoundEffect)
    }

    func getSoundEffectDisconnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.disconnectSoundEffect)
    }

    func saveCustomSoundEffectPathConnect(_ path: String) {
        sharedDefault?.set(path, forKey: SharedKeys.customSoundEffectPathConnect)
    }

    func saveCustomSoundEffectPathDisconnect(_ path: String) {
        sharedDefault?.set(path, forKey: SharedKeys.customSoundEffectPathDisconnect)
    }

    func getCustomSoundEffectPathConnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.customSoundEffectPathConnect)
    }

    func getCustomSoundEffectPathDisconnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.customSoundEffectPathDisconnect)
    }

    // Backgrounds
    func saveBackgroundEffectConnect(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.connectBackgroundEffect)
    }

    func getBackgroundEffectConnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.connectBackgroundEffect)
    }

    func backgroundEffectConnect() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.connectBackgroundEffect, type: String.self)
    }

    func saveBackgroundCustomConnectPath(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.connectBackgroundCustomPath)
    }

    func getBackgroundCustomConnectPath() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.connectBackgroundCustomPath)
    }

    func backgroundCustomConnectPath() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.connectBackgroundCustomPath, type: String.self)
    }

    func saveBackgroundEffectDisconnect(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.disconnectBackgroundEffect)
    }

    func getBackgroundEffectDisconnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.disconnectBackgroundEffect)
    }

    func backgroundEffectDisconnect() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.disconnectBackgroundEffect, type: String.self)
    }

    func saveBackgroundCustomDisconnectPath(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.disconnectBackgroundCustomPath)
    }

    func getBackgroundCustomDisconnectPath() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.disconnectBackgroundCustomPath)
    }

    func backgroundCustomDisconnectPath() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.disconnectBackgroundCustomPath, type: String.self)
    }

    // Custom Locations Names {
    func saveCustomLocationsNames(value: [ExportedRegion]) {
        saveObject(object: value, forKey: SharedKeys.customLocationNames)
    }

    func getCustomLocationsNames() -> [ExportedRegion] {
        getObject(forKey: SharedKeys.customLocationNames) ?? []
    }
}

// MARK: Utility Methods

extension PreferencesImpl {
    func getString(forKey: String) -> String? {
        return sharedDefault?.string(forKey: forKey)
    }

    func setString(_ value: String?, forKey: String) {
        sharedDefault?.setValue(value, forKey: forKey)
    }

    func getBool(key: String) -> Bool {
        return sharedDefault?.bool(forKey: key) ?? false
    }

    func setBool(_ value: Bool?, forKey: String) {
        sharedDefault?.setValue(value, forKey: forKey)
    }

    func getInt(forKey: String) -> Int? {
        return sharedDefault?.integer(forKey: forKey)
    }

    func setInt(_ value: Int?, forKey: String) {
        sharedDefault?.setValue(value, forKey: forKey)
    }

    func getDate(forKey: String) -> Date? {
        guard let date = sharedDefault?.object(forKey: forKey) as? Date else { return nil }
        return date
    }

    func setDate(_: Any?, forKey: String) {
        sharedDefault?.set(Date(), forKey: forKey)
    }

    func getDouble(forKey: String) -> Double? {
        return sharedDefault?.double(forKey: forKey)
    }

    func setDouble(_ value: Double?, forKey: String) {
        sharedDefault?.setValue(value, forKey: forKey)
    }

    func getData(key: String) -> Any? {
        return sharedDefault?.value(forKey: key)
    }

    func saveData(value: Any, key: String) {
        sharedDefault?.setValue(value, forKey: key)
    }

    func removeData(key: String) {
        sharedDefault?.removeObject(forKey: key)
    }

    func saveObject<T: Codable>(object: T, forKey: String) {
        do {
            let data = try JSONEncoder().encode(object)
            sharedDefault?.set(data, forKey: forKey)
        } catch {
            //TODO: Add logger
        }
    }

    func getObject<T: Codable>(forKey: String) -> T? {
        guard let data = sharedDefault?.data(forKey: forKey) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // TODO: Add logger
            return nil
        }
    }

    func removeObjects(forKey: [String]) {
        for key in forKey {
            sharedDefault?.removeObject(forKey: key)
        }
    }
}

//
//  MockPreferences.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-02-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

@testable import Windscribe

class MockPreferences: Preferences {

    var mockConnectionCount = 0
    var mockAdvanceParams: String?
    var mockLastReviewDate: Date?
    var mockLoginDate: Date?
    var mockHasReviewed = false

    // Additional mock storage variables
    var mockLanguage: String?
    var mockSelectedProtocol: String?
    var mockSelectedPort: String?
    var mockFirewallMode: Bool?
    var mockKillSwitch: Bool?
    var mockDarkMode: Bool?
    var mockConnectionMode: String?
    var mockFavouriteIds: [String] = []
    var mockCustomLocations: [ExportedRegion] = []
    private let favouriteIdsSubject = CurrentValueSubject<[String], Never>([])
    var mockLastSelectedLocation: String = ""
    var mockBestLocation: String = ""
    var clearWireGuardConfigurationCalled = false
    var mockLastNodeIP: String?
    var mockIgnorePinIP: Bool?

    // UserSessionRepository tracking
    var sessionAuthToReturn: String?
    var lastSavedSessionAuth: String?

    // Background/Look and Feel mock storage
    var mockAspectRatio: String?
    var mockBackgroundEffectConnect: String?
    var mockBackgroundEffectDisconnect: String?
    var mockBackgroundCustomConnectPath: String?
    var mockBackgroundCustomDisconnectPath: String?
    private let darkModeSubject = CurrentValueSubject<Bool?, Never>(nil)

    func saveAdvanceParams(params: String) {
        mockAdvanceParams = params
    }

    func getAdvanceParams() -> AnyPublisher<String?, Never> {
        return Just(mockAdvanceParams).eraseToAnyPublisher()
    }

    func getAdvanceParams() -> String? {
        return mockAdvanceParams
    }

    func getConnectionCount() -> Int {
        return mockConnectionCount
    }

    func getWhenRateUsPopupDisplayed() -> Date? {
        return mockLastReviewDate
    }

    func getLoginDate() -> Date? {
        return mockLoginDate
    }

    func getRateUsActionCompleted() -> Bool {
        return mockHasReviewed
    }

    func saveWhenRateUsPopupDisplayed(date: Date) {
        mockLastReviewDate = date
    }

    func saveRateUsActionCompleted(bool: Bool) {
        mockHasReviewed = bool
    }

    func saveUserSessionAuth(sessionAuth: String?) {
        lastSavedSessionAuth = sessionAuth
    }

    func userSessionAuth() -> String? {
        return sessionAuthToReturn
    }

    func saveOrderLocationsBy(order: String) {}

    func getOrderLocationsBy() -> AnyPublisher<String?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func getOrderLocationsBySync() -> String? {
        return nil
    }

    func saveLanguage(language: String) {
        mockLanguage = language
    }

    func getLanguage() -> AnyPublisher<String?, Never> {
        return Just(mockLanguage).eraseToAnyPublisher()
    }

    func saveFirewallMode(firewall: Bool) {
        mockFirewallMode = firewall
    }

    func getFirewallMode() -> AnyPublisher<Bool?, Never> {
        return Just(mockFirewallMode).eraseToAnyPublisher()
    }

    func saveKillSwitch(killSwitch: Bool) {
        mockKillSwitch = killSwitch
    }

    func getKillSwitch() -> AnyPublisher<Bool?, Never> {
        return Just(mockKillSwitch).eraseToAnyPublisher()
    }

    func getKillSwitchSync() -> Bool {
        return false
    }

    func saveAllowLane(mode: Bool) {}

    func getAllowLaneSync() -> Bool {
        return false
    }

    func getAllowLAN() -> AnyPublisher<Bool?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func saveHapticFeedback(haptic: Bool) {}

    func getHapticFeedback() -> AnyPublisher<Bool?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func saveSelectedProtocol(selectedProtocol: String) {
        mockSelectedProtocol = selectedProtocol
    }

    func getSelectedProtocol() -> AnyPublisher<String?, Never> {
        return Just(mockSelectedProtocol).eraseToAnyPublisher()
    }

    func saveSelectedPort(port: String) {
        mockSelectedPort = port
    }

    func getSelectedPort() -> AnyPublisher<String?, Never> {
        return Just(mockSelectedPort).eraseToAnyPublisher()
    }

    func saveShowServerHealth(show: Bool) {}

    func getShowServerHealth() -> AnyPublisher<Bool?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func saveDarkMode(darkMode: Bool) {
        mockDarkMode = darkMode
        darkModeSubject.send(darkMode)
    }

    func getDarkMode() -> AnyPublisher<Bool?, Never> {
        return darkModeSubject.eraseToAnyPublisher()
    }

    func savePingMethod(method: String) {}

    func getPingMethod() -> AnyPublisher<String?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func getPingMethodSync() -> String {
        return ""
    }

    func getConnectionCount() -> Int? {
        return mockConnectionCount
    }

    func increaseConnectionCount() {
        mockConnectionCount += 1
    }

    func saveConnectionCount(count: Int) {
        mockConnectionCount = count
    }

    func getLastConnectedNetworkName() -> String? {
        return nil
    }

    func saveLastConnectedNetworkName(network: String) {}

    func getNativeRateUsPopupDisplayCount() -> Int? {
        return 0
    }

    func saveNativeRateUsPopupDisplayCount(count: Int) {}

    func getPrivacyPopupAccepted() -> Bool? {
        return false
    }

    func savePrivacyPopupAccepted(bool: Bool) {}

    func getShakeForDataHighestScore() -> Int? {
        return 0
    }

    func saveShakeForDataHighestScore(score: Int) {}

    func getUnlockShakeForData() -> Bool? {
        return false
    }

    func saveUnlockShakeForData(bool: Bool?) {}

    func saveBlurStaticIpAddress(bool: Bool?) {}

    func getBlurStaticIpAddress() -> Bool? {
        return false
    }

    func saveLastNodeIP(nodeIp: String) {
        mockLastNodeIP = nodeIp
    }

    func getLastNodeIP() -> String? {
        return mockLastNodeIP
    }

    func saveBlurNetworkName(bool: Bool?) {}

    func getBlurNetworkName() -> Bool? {
        return false
    }

    func saveSelectedLanguage(language: String?) {}

    func getSelectedLanguage() -> String? {
        return nil
    }

    func saveDefaultLanguage(language: String?) {}

    func getDefaultLanguage() -> String? {
        return nil
    }

    func saveActiveManagerKey(key: String?) {}

    func getActiveManagerKey() -> String? {
        return nil
    }

    func saveRegisteredForPushNotifications(bool: Bool?) {}

    func getRegisteredForPushNotifications() -> Bool? {
        return false
    }

    func saveFirstInstall(bool: Bool?) {}

    func getFirstInstall() -> Bool? {
        return false
    }

    func saveActiveAppleSig(sig: String?) {}

    func getActiveAppleSig() -> String? {
        return nil
    }

    func saveActiveAppleData(data: String?) {}

    func getActiveAppleData() -> String? {
        return nil
    }

    func saveActiveAppleID(id: String?) {}

    func getActiveAppleID() -> String? {
        return nil
    }

    func saveAppleLanguage(languge: String?) {}

    func getAppleLanguage() -> String? {
        return nil
    }

    func saveLastNotificationTimestamp(timeStamp: Double?) {}

    func getLastNotificationTimestamp() -> Double? {
        return nil
    }

    func saveSessionAuthHash(sessionAuth: String) {}

    func getSessionAuthHash() -> String? {
        return nil
    }

    func saveCountryOverrride(value: String?) {}

    func getCountryOverride() -> String? {
        return nil
    }

    func getLanguageManagerLanguage() -> String? {
        return nil
    }

    func saveServerNameKey(key: String?) {}

    func getServerNameKey() -> String? {
        return nil
    }

    func saveCountryCodeKey(key: String?) {}

    func getcountryCodeKey() -> String? {
        return nil
    }

    func saveNickNameKey(key: String?) {}

    func getNickNameKey() -> String? {
        return nil
    }

    func getCircumventCensorshipEnabled() -> AnyPublisher<Bool, Never> {
        return Just(false).eraseToAnyPublisher()
    }

    func isCircumventCensorshipEnabled() -> Bool {
        return false
    }

    func saveCircumventCensorshipStatus(status: Bool) {}

    func setLanguageManagerSelectedLanguage(language: Windscribe.Languages) {}

    func setLanguageManagerDefaultLanguage(language: String) {}

    func getLanguageManagerDefaultLanguage() -> String? {
        return nil
    }

    func getLanguageManagerSelectedLanguage() -> AnyPublisher<String?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func getServerCredentialTypeKey() -> String? {
        return nil
    }

    func setServerCredentialTypeKey(typeKey: String) {}

    func getAutoSecureNewNetworks() -> AnyPublisher<Bool?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func saveAutoSecureNewNetworks(autoSecure: Bool) {}

    func getConnectionMode() -> AnyPublisher<String?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func getConnectedDNSObservable() -> AnyPublisher<String?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func getConnectedDNS() -> String {
        return ""
    }

    func saveConnectionMode(mode: String) {}

    func saveConnectedDNS(mode: String) {}

    func saveShowedShareDialog(showed: Bool) {}

    func getShowedShareDialog() -> Bool {
        return false
    }

    func getConnectionModeSync() -> String {
        return ""
    }

    func getSelectedProtocolSync() -> String {
        return ""
    }

    func getSelectedPortSync() -> String {
        return ""
    }

    func getServerSettings() -> String {
        return ""
    }

    func saveServerSettings(settings: String) {}

    func saveCustomDNSValue(value: Windscribe.DNSValue) {}

    func getCustomDNSValue() -> Windscribe.DNSValue {
        return Windscribe.DNSValue(type: .ipAddress, value: "", servers: [])
    }

    func saveWireguardWakeupTime(value: Double) {}

    func getWireguardWakeupTime() -> Double {
        return 0.0
    }

    func saveForceDisconnect(value: Bool) {}

    func getForceDisconnect() -> AnyPublisher<Bool?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func observeFavouriteIds() -> AnyPublisher<[String], Never> {
        return favouriteIdsSubject.eraseToAnyPublisher()
    }

    func addFavouriteId(_ id: String) {
        if !mockFavouriteIds.contains(id) {
            mockFavouriteIds.append(id)
            favouriteIdsSubject.send(mockFavouriteIds)
        }
    }

    func removeFavouriteId(_ id: String) {
        mockFavouriteIds.removeAll { $0 == id }
        favouriteIdsSubject.send(mockFavouriteIds)
    }

    func clearFavourites() {
        mockFavouriteIds.removeAll()
        favouriteIdsSubject.send(mockFavouriteIds)
    }

    func saveLoginDate(date: Date) {}

    func saveConnectionRequested(value: Bool) {}

    func getConnectionRequested() -> Bool {
        return false
    }

    func clearSelectedLocations() {
        mockLastSelectedLocation = ""
        mockBestLocation = ""
    }

    func saveLastSelectedLocation(with locationID: String) {
        mockLastSelectedLocation = locationID
    }

    func getLastSelectedLocation() -> String {
        return mockLastSelectedLocation
    }

    func saveBestLocation(with locationID: String) {
        mockBestLocation = locationID
    }

    func getBestLocation() -> String {
        return mockBestLocation
    }

    func isCustomConfigSelected() -> Bool {
        return false
    }

    func getLocationType() -> Windscribe.LocationType? {
        return nil
    }

    func getLocationType(id: String) -> Windscribe.LocationType? {
        return nil
    }

    func saveAspectRatio(value: String) {
        mockAspectRatio = value
    }

    func getAspectRatio() -> String? {
        return mockAspectRatio
    }

    func aspectRatio() -> AnyPublisher<String?, Never> {
        return Just(mockAspectRatio).eraseToAnyPublisher()
    }

    func saveBackgroundEffectConnect(value: String) {
        mockBackgroundEffectConnect = value
    }

    func getBackgroundEffectConnect() -> String? {
        return mockBackgroundEffectConnect
    }

    func saveBackgroundCustomConnectPath(value: String) {
        mockBackgroundCustomConnectPath = value
    }

    func getBackgroundCustomConnectPath() -> String? {
        return mockBackgroundCustomConnectPath
    }

    func saveBackgroundEffectDisconnect(value: String) {
        mockBackgroundEffectDisconnect = value
    }

    func getBackgroundEffectDisconnect() -> String? {
        return mockBackgroundEffectDisconnect
    }

    func saveBackgroundCustomDisconnectPath(value: String) {
        mockBackgroundCustomDisconnectPath = value
    }

    func getBackgroundCustomDisconnectPath() -> String? {
        return mockBackgroundCustomDisconnectPath
    }

    func saveSoundEffectConnect(value: String) {}

    func getSoundEffectConnect() -> String? {
        return nil
    }

    func saveSoundEffectDisconnect(value: String) {}

    func getSoundEffectDisconnect() -> String? {
        return nil
    }

    func saveCustomSoundEffectPathConnect(_ path: String) {}

    func saveCustomSoundEffectPathDisconnect(_ path: String) {}

    func getCustomSoundEffectPathConnect() -> String? {
        return nil
    }

    func getCustomSoundEffectPathDisconnect() -> String? {
        return nil
    }

    func saveCustomLocationsNames(value: [Windscribe.ExportedRegion]) {
        mockCustomLocations = value
    }

    func getCustomLocationsNames() -> [ExportedRegion] {
        return mockCustomLocations
    }

    func saveWireGuardAddress(_ address: String?) {}

    func getWireGuardAddress() -> String? {
        return nil
    }

    func saveWireGuardDNS(_ dns: String?) {}

    func getWireGuardDNS() -> String? {
        return nil
    }

    func saveWireGuardPresharedKey(_ key: String?) {}

    func getWireGuardPresharedKey() -> String? {
        return nil
    }

    func saveWireGuardAllowedIPs(_ ips: String?) {}

    func getWireGuardAllowedIPs() -> String? {
        return nil
    }

    func saveWireGuardServerEndpoint(_ endpoint: String?) {}

    func getWireGuardServerEndpoint() -> String? {
        return nil
    }

    func saveWireGuardServerHostname(_ hostname: String?) {}

    func getWireGuardServerHostname() -> String? {
        return nil
    }

    func saveWireGuardServerPublicKey(_ key: String?) {}

    func getWireGuardServerPublicKey() -> String? {
        return nil
    }

    func saveWireGuardServerPort(_ port: String?) {}

    func getWireGuardServerPort() -> String? {
        return nil
    }

    func clearWireGuardConfiguration() {
        clearWireGuardConfigurationCalled = true
    }

    func getSelectedProtocolSync() -> String? {
        return mockSelectedProtocol
    }

    func getSelectedPortSync() -> String? {
        return mockSelectedPort
    }

    func saveIgnorePinIP(status: Bool) {
        mockIgnorePinIP = status
    }

    func getIgnorePinIP() -> Bool {
        return mockIgnorePinIP ?? false
    }
}

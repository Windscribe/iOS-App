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
    var mockSelectedPort: String?
    var mockFirewallMode: Bool?
    var mockKillSwitch: Bool?
    var mockDarkMode: Bool?
    var mockSelectedProtocol = CurrentValueSubject<String?,Never>(VPNProtocolType.wireGuard.identifier)
    var mockConnectionMode = CurrentValueSubject<String?,Never>(Fields.Values.manual)
    var mockFavouriteIds: [String] = []
    var mockCustomLocations: [ExportedRegion] = []
    private let favouriteIdsSubject = CurrentValueSubject<[String], Never>([])
    var mockLastSelectedLocation: String = ""
    var mockBestLocation: String = ""
    var clearWireGuardConfigurationCalled = false
    var mockLastNodeIP: String?
    var mockIgnorePinIP: Bool?
    var mockWireGuardHashedCIDR: [String]?
    var mockWireGuardHashedCIDRv6: [String]?
    var mockWireGuardAllowedIPsV6: String?
    var mockWireGuardAddressV6: String?
    var mockEgressProtocolPreference: String = DefaultValues.ipStack
    var mockLastSelectedPinnedIp: String?
    var mockUnblockWgParams: Windscribe.UnblockWgParams?
    var disconnectReason: Windscribe.DisconnectReason?
    var userStatus: Bool?
    var mockPrivacyPopupAccepted: Bool? = false
    var mockTunnelStoppedForAppUpdate = false

    // WireGuard configuration storage
    var mockWireGuardAddress: String?
    var mockWireGuardDNS: String?
    var mockWireGuardPresharedKey: String?
    var mockWireGuardAllowedIPs: String?
    var mockWireGuardServerEndpoint: String?
    var mockWireGuardServerHostname: String?
    var mockWireGuardServerPublicKey: String?
    var mockWireGuardServerPort: String?

    // IP Address - Issue #911
    var mockCurrentIpAddress: String? {
        didSet {
            currentIpAddressSubject.send(mockCurrentIpAddress)
        }
    }
    private let currentIpAddressSubject = CurrentValueSubject<String?, Never>(nil)

    // UserSessionRepository tracking
    var sessionAuthToReturn: String?
    var lastSavedSessionAuth: String?

    // Migration tracking
    var mockFirstInstall: Bool? = false
    var mockUserDefaultsSessionAuth: String?
    var clearUserDefaultsSessionAuthCalled = false
    var clearSessionAuthCalled = false
    var saveSessionAuthHashCalled = false

    // Background/Look and Feel mock storage
    var mockAspectRatio: String?
    var mockBackgroundEffectConnect: String?
    var mockBackgroundEffectDisconnect: String?
    var mockBackgroundCustomConnectPath: String?
    var mockBackgroundCustomDisconnectPath: String?
    var mockCustomAppIcon: String?
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

    func getHapticFeedbackSync() -> Bool { false }

    func saveSelectedProtocol(selectedProtocol: String) {
        mockSelectedProtocol.send(selectedProtocol)
    }

    func getSelectedProtocol() -> AnyPublisher<String?, Never> {
        return mockSelectedProtocol.eraseToAnyPublisher()
    }

    func saveSelectedPort(port: String) {
        mockSelectedPort = port
    }

    func getSelectedPort() -> AnyPublisher<String?, Never> {
        return Just(mockSelectedPort).eraseToAnyPublisher()
    }

    func saveShowServerNetLoad(show: Bool) {}

    func getShowServerNetLoad() -> AnyPublisher<Bool?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func getShowServerNetLoadSync() -> Bool { false }

    func saveDarkMode(darkMode: Bool) {
        mockDarkMode = darkMode
        darkModeSubject.send(darkMode)
    }

    func getDarkMode() -> AnyPublisher<Bool?, Never> {
        return darkModeSubject.eraseToAnyPublisher()
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

    func getNativeRateUsPopupDisplayCount() -> Int? {
        return 0
    }

    func saveNativeRateUsPopupDisplayCount(count: Int) {}

    func getPrivacyPopupAccepted() -> Bool? {
        return mockPrivacyPopupAccepted
    }

    func savePrivacyPopupAccepted(bool: Bool) {
        mockPrivacyPopupAccepted = bool
    }

    func getShakeForDataHighestScore() -> Int? {
        return 0
    }

    func saveShakeForDataHighestScore(score: Int) {}

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

    func saveFirstInstall(bool: Bool?) {
        mockFirstInstall = bool
    }

    func getFirstInstall() -> Bool? {
        return mockFirstInstall
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

    // MARK: - OpenVPN + IKEv2 Server Credentials

    var mockOpenVPNCredentials: ServerCredentialsModel?
    var mockIKEv2Credentials: ServerCredentialsModel?

    var saveOpenVPNCredentialsCalled = false
    func saveOpenVPNCredentials(_ credentials: ServerCredentialsModel) { saveOpenVPNCredentialsCalled = true; mockOpenVPNCredentials = credentials }
    func getOpenVPNCredentials() -> ServerCredentialsModel? { mockOpenVPNCredentials }
    func deleteOpenVPNCredentials() { mockOpenVPNCredentials = nil }

    var saveIKEv2CredentialsCalled = false
    func saveIKEv2Credentials(_ credentials: ServerCredentialsModel) { saveIKEv2CredentialsCalled = true; mockIKEv2Credentials = credentials }
    func getIKEv2Credentials() -> ServerCredentialsModel? { mockIKEv2Credentials }
    func deleteIKEv2Credentials() { mockIKEv2Credentials = nil }

    // MARK: - Custom Config Credentials

    private var customConfigCredentials: [String: ServerCredentialsModel] = [:]
    private var storedSessionData: Data?

    func saveCustomConfigCredentials(configId: String, credentials: ServerCredentialsModel) {
        customConfigCredentials[configId] = credentials
    }

    func getCustomConfigCredentials(configId: String) -> ServerCredentialsModel? {
        return customConfigCredentials[configId]
    }

    func deleteCustomConfigCredentials(configId: String) {
        customConfigCredentials.removeValue(forKey: configId)
    }

    func getAllCustomConfigCredentials() -> [String: ServerCredentialsModel] {
        return customConfigCredentials
    }

    func saveAllCustomConfigCredentials(_ credentials: [String: ServerCredentialsModel]) {
        customConfigCredentials = credentials
    }

    func deleteAllCustomConfigCredentials() {
        customConfigCredentials.removeAll()
    }

    func saveStoredSession(_ data: Data) throws {
        storedSessionData = data
    }

    func getStoredSession() throws -> Data? {
        return storedSessionData
    }

    func deleteStoredSession() {
        storedSessionData = nil
    }

    func saveSSOProvider(provider: String?) {}

    func getSSOProvider() -> String? {
        return nil
    }

    func saveLastNotificationTimestamp(timeStamp: Double?) {}

    func getLastNotificationTimestamp() -> Double? {
        return nil
    }

    func saveLastUpdatePromptTimestamp(timeStamp: Double?) {}

    func getLastUpdatePromptTimestamp() -> Double? {
        return nil
    }

    func saveLastUpdateCheckTimestamp(timeStamp: Double?) {}

    func getLastUpdateCheckTimestamp() -> Double? {
        return nil
    }

    func saveTunnelStoppedForAppUpdate(status: Bool) {
        mockTunnelStoppedForAppUpdate = status
    }

    func getTunnelStoppedForAppUpdate() -> Bool {
        return mockTunnelStoppedForAppUpdate
    }

    func clearUserDefaultsSessionAuth() {
        clearUserDefaultsSessionAuthCalled = true
        mockUserDefaultsSessionAuth = nil
    }

    func getUserDefaultsSessionAuth() -> String? {
        return mockUserDefaultsSessionAuth
    }

    func clearSessionAuth() {
        clearSessionAuthCalled = true
        sessionAuthToReturn = nil
        lastSavedSessionAuth = nil
    }

    func saveSessionAuthHash(sessionAuth: String) {
        saveSessionAuthHashCalled = true
        sessionAuthToReturn = sessionAuth
        lastSavedSessionAuth = sessionAuth
    }

    func getSessionAuthHash() -> String? {
        return sessionAuthToReturn
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

    func getLanguageManagerSelectedLanguage() -> AnyPublisher<String?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func setServerCredentialTypeKey(typeKey: String) {}

    func getAutoSecureNewNetworks() -> AnyPublisher<Bool?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    func saveAutoSecureNewNetworks(autoSecure: Bool) {}

    func getConnectionMode() -> AnyPublisher<String?, Never> {
        return mockConnectionMode.eraseToAnyPublisher()
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
        return mockConnectionMode.value ?? Fields.Values.manual
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

    func clearSelectedLocations() {
        mockLastSelectedLocation = ""
        mockBestLocation = ""
    }

    func saveLastConnectionTarget(with targetId: String) {
        mockLastSelectedLocation = targetId
    }

    func getLastConnectionTarget() -> String {
        return mockLastSelectedLocation
    }

    func saveBestLocation(with datacenterId: String) {
        mockBestLocation = datacenterId
    }

    func getBestLocation() -> String {
        return mockBestLocation
    }

    func isCustomConfigSelected() -> Bool {
        return false
    }

    func getConnectionTargetType() -> Windscribe.ConnectionTargetType? {
        return nil
    }

    func getConnectionTargetType(id: String) -> Windscribe.ConnectionTargetType? {
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

    func saveCustomAppIcon(value: String) {
        mockCustomAppIcon = value
    }

    func getCustomAppIcon() -> String? {
        return mockCustomAppIcon
    }

    func saveWireGuardAddress(_ address: String?) {
        mockWireGuardAddress = address
    }

    func getWireGuardAddress() -> String? {
        return mockWireGuardAddress
    }

    func saveWireGuardDNS(_ dns: String?) {
        mockWireGuardDNS = dns
    }

    func getWireGuardDNS() -> String? {
        return mockWireGuardDNS
    }

    func saveWireGuardPresharedKey(_ key: String?) {
        mockWireGuardPresharedKey = key
    }

    func getWireGuardPresharedKey() -> String? {
        return mockWireGuardPresharedKey
    }

    func saveWireGuardAllowedIPs(_ ips: String?) {
        mockWireGuardAllowedIPs = ips
    }

    func getWireGuardAllowedIPs() -> String? {
        return mockWireGuardAllowedIPs
    }

    func saveWireGuardAllowedIPsV6(_ ips: String?) {
        mockWireGuardAllowedIPsV6 = ips
    }

    func getWireGuardAllowedIPsV6() -> String? {
        return mockWireGuardAllowedIPsV6
    }

    func saveWireGuardServerEndpoint(_ endpoint: String?) {
        mockWireGuardServerEndpoint = endpoint
    }

    func getWireGuardServerEndpoint() -> String? {
        return mockWireGuardServerEndpoint
    }

    func saveWireGuardServerHostname(_ hostname: String?) {
        mockWireGuardServerHostname = hostname
    }

    func getWireGuardServerHostname() -> String? {
        return mockWireGuardServerHostname
    }

    func saveWireGuardServerPublicKey(_ publicKey: String?) {
        mockWireGuardServerPublicKey = publicKey
    }

    func getWireGuardServerPublicKey() -> String? {
        return mockWireGuardServerPublicKey
    }

    func saveWireGuardServerPort(_ port: String?) {
        mockWireGuardServerPort = port
    }

    func getWireGuardServerPort() -> String? {
        return mockWireGuardServerPort
    }

    var mockWireGuardServerSupportsIPv6: Bool = false

    func saveWireGuardServerSupportsIPv6(_ supports: Bool) {
        mockWireGuardServerSupportsIPv6 = supports
    }

    func getWireGuardServerSupportsIPv6() -> Bool {
        return mockWireGuardServerSupportsIPv6
    }

    func clearWireGuardConfiguration() {
        clearWireGuardConfigurationCalled = true
        mockWireGuardAddress = nil
        mockWireGuardAddressV6 = nil
        mockWireGuardDNS = nil
        mockWireGuardPresharedKey = nil
        mockWireGuardAllowedIPs = nil
        mockWireGuardAllowedIPsV6 = nil
        mockWireGuardServerEndpoint = nil
        mockWireGuardServerHostname = nil
        mockWireGuardServerPublicKey = nil
        mockWireGuardServerPort = nil
        mockWireGuardServerSupportsIPv6 = false
        mockWireGuardHashedCIDR = nil
        mockWireGuardHashedCIDRv6 = nil
    }

    func getSelectedProtocolSync() -> String? {
        return mockSelectedProtocol.value
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

    func saveCurrentIpAddress(ip: String?) {
        mockCurrentIpAddress = ip
        // Note: currentIpAddressSubject.send() happens in mockCurrentIpAddress's didSet
    }

    func getCurrentIpAddress() -> String? {
        return mockCurrentIpAddress
    }

    func getCurrentIpAddressObservable() -> AnyPublisher<String?, Never> {
        return currentIpAddressSubject.eraseToAnyPublisher()
    }

    func saveWireGuardHashedCIDR(_ cidr: [String]?) {
        mockWireGuardHashedCIDR = cidr
    }

    func getWireGuardHashedCIDR() -> [String]? {
        return mockWireGuardHashedCIDR
    }

    func saveWireGuardHashedCIDRv6(_ cidr: [String]?) {
        mockWireGuardHashedCIDRv6 = cidr
    }

    func getWireGuardHashedCIDRv6() -> [String]? {
        return mockWireGuardHashedCIDRv6
    }

    func saveWireGuardAddressV6(_ address: String?) {
        mockWireGuardAddressV6 = address
    }

    func getWireGuardAddressV6() -> String? {
        return mockWireGuardAddressV6
    }

    func saveEgressProtocolPreference(value: String) {
        mockEgressProtocolPreference = value
    }

    func getEgressProtocolPreference() -> AnyPublisher<String?, Never> {
        return Just(mockEgressProtocolPreference).eraseToAnyPublisher()
    }

    func getEgressProtocolPreferenceSync() -> String {
        return mockEgressProtocolPreference
    }

    func saveIngressProtocolPreference(value: String) {
    }

    func getIngressProtocolPreference() -> AnyPublisher<String?, Never> {
        return Just(DefaultValues.ipStack).eraseToAnyPublisher()
    }

    func getIngressProtocolPreferenceSync() -> String {
        return DefaultValues.ipStack
    }

    func saveLastSelectedPinnedIp(with pinnedIP: String) {
        mockLastSelectedPinnedIp = pinnedIP
    }

    func getLastSelectedPinnedIp() -> String? {
        return mockLastSelectedPinnedIp
    }

    func saveUnblockWgParams(param: Windscribe.UnblockWgParams) {
        mockUnblockWgParams = param
    }

    func getUnblockWgParams() -> Windscribe.UnblockWgParams? {
        return mockUnblockWgParams
    }

    func saveDisconnectReason(reason: Windscribe.DisconnectReason) {
        disconnectReason = reason
    }

    func getDisconnectReason() -> Windscribe.DisconnectReason {
        disconnectReason ?? .unknown
    }

    func saveUserStatus(value: Bool) {
        userStatus = value
    }

    func getUserStatus() -> Bool {
        userStatus ?? false
    }

    func saveServerRevision(revision: Int64) {

    }

    func getServerRevision() -> Int64 {
        0
    }

    func saveHasIpBackup(backup: Bool) {
    }

    func getHasIpBackup() -> Bool {
        false
    }

    func saveRoutingType(routingType: Windscribe.ServerRoutingType) {
    }

    func getRoutingType() -> Windscribe.ServerRoutingType {
        .auto
    }

    // MARK: - Realm → GRDB migration flag

    var mockDidMigrateRealmToGRDB: Bool = false

    func didMigrateRealmToGRDB() -> Bool {
        return mockDidMigrateRealmToGRDB
    }

    func saveDidMigrateRealmToGRDB(_ value: Bool) {
        mockDidMigrateRealmToGRDB = value
    }

}

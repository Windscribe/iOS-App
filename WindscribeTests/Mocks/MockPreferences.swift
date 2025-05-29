//
//  MockPreferences.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-02-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

@testable import Windscribe

class MockPreferences: Preferences {

    var mockConnectionCount = 0

    var mockDataUsedMB = 0

    var mockLastReviewDate: Date?

    var mockLoginDate: Date?

    var mockHasReviewed = false

    func saveAdvanceParams(params: String) {}

    func getConnectionCount() -> Int { return mockConnectionCount }
    func getDataUsedInMB() -> Int { return mockDataUsedMB }
    func getWhenRateUsPopupDisplayed() -> Date? { return mockLastReviewDate }
    func getLoginDate() -> Date? { return mockLoginDate }
    func getRateUsActionCompleted() -> Bool { return mockHasReviewed }

    func saveWhenRateUsPopupDisplayed(date: Date) { mockLastReviewDate = date }
    func saveRateUsActionCompleted(bool: Bool) { mockHasReviewed = bool }

    func getAdvanceParams() -> Observable<String?> {
        return Observable.just(nil)
    }

    func getAdvanceParams() -> String? {
        nil
    }

    func getAdvanceParamsSync() -> String? {
        return nil
    }

    func saveUserSessionAuth(sessionAuth: String?) {}

    func userSessionAuth() -> String? {
        return nil
    }

    func saveLatencyType(latencyType: String) {}

    func getLatencyType() -> Observable<String> {
        return Observable.just("")
    }

    func saveOrderLocationsBy(order: String) {}

    func getOrderLocationsBy() -> Observable<String?> {
        return Observable.just(nil)
    }

    func saveAppSkinPreferences(type: String) {}

    func getAppSkinPreferences() -> Observable<String?> {
        return Observable.just(nil)
    }

    func saveAppearance(appearance: String) {}

    func getAppearance() -> Observable<String?> {
        return Observable.just(nil)
    }

    func saveLanguage(language: String) {}

    func getLanguage() -> Observable<String?> {
        return Observable.just(nil)
    }

    func saveFirewallMode(firewall: Bool) {}

    func getFirewallMode() -> Observable<Bool?> {
        return Observable.just(nil)
    }

    func saveKillSwitch(killSwitch: Bool) {}

    func getKillSwitch() -> Observable<Bool?> {
        return Observable.just(nil)
    }

    func getKillSwitchSync() -> Bool {
        return false
    }

    func saveAllowLane(mode: Bool) {}

    func getAllowLaneSync() -> Bool {
        return false
    }

    func getAllowLAN() -> Observable<Bool?> {
        return Observable.just(nil)
    }

    func saveHapticFeedback(haptic: Bool) {}

    func getHapticFeedback() -> Observable<Bool?> {
        return Observable.just(nil)
    }

    func saveSelectedProtocol(selectedProtocol: String) {}

    func getSelectedProtocol() -> Observable<String?> {
        return Observable.just(nil)
    }

    func saveSelectedPort(port: String) {}

    func getSelectedPort() -> Observable<String?> {
        return Observable.just(nil)
    }

    func saveShowServerHealth(show: Bool) {}

    func saveDarkMode(darkMode: Bool) {}

    func getDarkMode() -> Observable<Bool?> {
        return Observable.just(nil)
    }

    func getConnectionCount() -> Int? {
        return 0
    }

    func increaseConnectionCount() {}

    func saveConnectionCount(count: Int) {}

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

    func saveAppleLanguage(languge language: String?) {

    }

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

    func getCircumventCensorshipEnabled() -> Observable<Bool> {
        return Observable.just(false)
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

    func getLanguageManagerSelectedLanguage() -> Observable<String?> {
        return Observable.just(nil)
    }

    func getServerCredentialTypeKey() -> String? {
        return nil
    }

    func setServerCredentialTypeKey(typeKey: String) {}

    func getAutoSecureNewNetworks() -> Observable<Bool?> {
        return Observable.just(nil)
    }

    func saveAutoSecureNewNetworks(autoSecure: Bool) {}

    func getConnectionMode() -> Observable<String?> {
        return Observable.just(nil)
    }

    func getConnectedDNSObservable() -> Observable<String?> {
        return Observable.just(nil)
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

    func getForceDisconnect() -> Observable<Bool?> {
        return Observable.just(nil)
    }

    func observeFavouriteIds() -> Observable<[String]> {
        return Observable.just([])
    }

    func addFavouriteId(_ id: String) {}

    func removeFavouriteId(_ id: String) {}

    func clearFavourites() {}

    func saveLoginDate(date: Date) {}

    func saveConnectionRequested(value: Bool) {}

    func getConnectionRequested() -> Bool {
        return false
    }

    func clearSelectedLocations() {}

    func saveLastSelectedLocation(with locationID: String) {}

    func getLastSelectedLocation() -> String {
        return ""
    }

    func saveBestLocation(with locationID: String) {}

    func getBestLocation() -> String {
        return ""
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

    func saveHasCustomBackground(value: Bool) { }

    func getHasCustomBackground() -> Bool {
        return false
    }

    func getHasCustomBackgroundObservable() -> RxSwift.Observable<Bool?> {
        return Observable.just(nil)
    }

    func saveCurrentCustomBackground(value: String) { }

    func getCurrentCustomBackground() -> String? {
        return nil
    }
}

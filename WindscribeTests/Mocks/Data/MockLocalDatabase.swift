//
//  MockLocalDatabase.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-02-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine

@testable import Windscribe

class MockLocalDatabase: LocalDatabase {

    let sessionSubject = BehaviorSubject<Windscribe.Session?>(value: nil)
    let oldSessionSubject = BehaviorSubject<Windscribe.OldSession?>(value: nil)
    let notificationsSubject = BehaviorSubject<[Windscribe.Notice]>(value: [])
    let networksSubject = BehaviorSubject<[Windscribe.WifiNetwork]>(value: [])
    let readNoticesSubject = BehaviorSubject<[Windscribe.ReadNotice]>(value: [])

    var mockServers: [Server]? = []
    let mockFavoritesSubject = BehaviorSubject<[String: Favourite]>(value: [:])
    // PortMap tracking
    var savePortMapCalled = false
    var saveSuggestedPortsCalled = false
    var portMapsToReturn: [Windscribe.PortMap]?

    // Notifications tracking
    var saveNotificationsCalled = false
    var notificationsToReturn: [Windscribe.Notice]?

    // StaticIP tracking
    var staticIPsToReturn: [Windscribe.StaticIP]?
    var saveStaticIPsCalled = false
    var deleteStaticIpsCalled = false
    var lastDeletedStaticIPsIgnoreList: [String]?

    // Session tracking
    var saveOldSessionCalled = false

    // MobilePlan tracking
    var mobilePlansToReturn: [Windscribe.MobilePlan]?
    var saveMobilePlansCalled = false

    // WifiNetwork tracking
    var mockWifiNetworks: [Windscribe.WifiNetwork] = [] {
        didSet {
            networksSubject.onNext(mockWifiNetworks)
        }
    }
    var saveNetworkCalled = false
    var lastSavedNetwork: Windscribe.WifiNetwork?

    func migrate() {}

    func getMobilePlans() -> [Windscribe.MobilePlan]? {
        return mobilePlansToReturn
    }

    func saveMobilePlans(mobilePlansList: [Windscribe.MobilePlan]) {
        saveMobilePlansCalled = true
        mobilePlansToReturn = mobilePlansList
    }

    func getServers() -> [Windscribe.Server]? {
        return mockServers
    }

    func saveServers(servers: [Windscribe.Server]) {
        mockServers = servers
    }

    func getStaticIPs() -> [Windscribe.StaticIP]? {
        return staticIPsToReturn
    }

    func saveStaticIPs(staticIps: [Windscribe.StaticIP]) {
        saveStaticIPsCalled = true
        staticIPsToReturn = staticIps
    }

    func deleteStaticIps(ignore: [String]) {
        deleteStaticIpsCalled = true
        lastDeletedStaticIPsIgnoreList = ignore
    }

    func getOpenVPNServerCredentials() -> Windscribe.OpenVPNServerCredentials? {
        return nil
    }

    func saveOpenVPNServerCredentials(credentials: Windscribe.OpenVPNServerCredentials) -> Disposable {
        return Disposables.create()
    }

    func getIKEv2ServerCredentials() -> Windscribe.IKEv2ServerCredentials? {
        return nil
    }

    func saveIKEv2ServerCredentials(credentials: Windscribe.IKEv2ServerCredentials) -> Disposable {
        return Disposables.create()
    }

    func getPortMap() -> [Windscribe.PortMap]? {
        return portMapsToReturn
    }

    func savePortMap(portMap: [Windscribe.PortMap]) {
        savePortMapCalled = true
    }

    func saveSuggestedPorts(suggestedPorts: [Windscribe.SuggestedPorts]) {
        saveSuggestedPortsCalled = true
    }

    func getSuggestedPorts() -> [Windscribe.SuggestedPorts]? {
        return []
    }

    func getNotificationsObservable() -> Observable<[Windscribe.Notice]> {
        return notificationsSubject.asObservable()
    }

    func saveNotifications(notifications: [Windscribe.Notice]) async {
        saveNotificationsCalled = true
        notificationsToReturn = notifications
        // Trigger the subject to simulate Realm notification
        notificationsSubject.onNext(notifications)
    }

    func getReadNotices() -> [Windscribe.ReadNotice]? {
        return try? readNoticesSubject.value()
    }

    func getReadNoticesObservable() -> Observable<[Windscribe.ReadNotice]> {
        return readNoticesSubject
    }

    func saveReadNotices(readNotices: [Windscribe.ReadNotice]) {
        readNoticesSubject.onNext(readNotices)
    }

    func getIp() -> Observable<Windscribe.MyIP?> {
        return Observable.just(nil)
    }

    func getIpSync() -> Windscribe.MyIP? {
        return nil
    }

    func saveIp(myip: Windscribe.MyIP) -> Disposable {
        return Disposables.create()
    }

    func getNetworks() -> Observable<[Windscribe.WifiNetwork]> {
        return networksSubject.asObservable()
    }

    func removeNetwork(wifiNetwork: Windscribe.WifiNetwork) {
        mockWifiNetworks.removeAll { $0.SSID == wifiNetwork.SSID }
    }

    func addPingData(pingData: Windscribe.PingData) {}

    func getAllPingData() -> [Windscribe.PingData] {
        return []
    }

    func saveCustomConfig(customConfig: Windscribe.CustomConfig) {
        // Mock implementation - no-op
    }

    func removeCustomConfig(fileId: String) {}

    func getPorts(protocolType: String) -> [String]? {
        return []
    }

    func getRobertFilters() -> Windscribe.RobertFilters? {
        return nil
    }

    func saveRobertFilters(filters: Windscribe.RobertFilters) -> Disposable {
        return Disposables.create()
    }

    func saveLastConnetion(vpnConnection: Windscribe.VPNConnection) -> Disposable {
        return Disposables.create()
    }

    func toggleRobertRule(id: String) {}

    func updateCustomConfigName(customConfigId: String, name: String) {}

    func updateCustomConfigCredentials(customConfigId: String, username: String, password: String) {}

    func saveOldSession() {
        saveOldSessionCalled = true
        guard let oldSession = try? sessionSubject.value() else {
            return
        }
        oldSessionSubject.onNext(OldSession(session: oldSession))
    }

    func getOldSession() -> Windscribe.OldSession? {
        return try? oldSessionSubject.value()
    }

    func getSession() -> Observable<Windscribe.Session?> {
        return sessionSubject.asObservable()
    }

    func getSessionSync() -> Windscribe.Session? {
        return try? sessionSubject.value()
    }

    func saveSession(session: Windscribe.Session) {
        // Trigger the subject to simulate Realm notification
        sessionSubject.onNext(session)
    }

    func updateConnectionMode(value: String) {}

    func clean() {
        saveNetworkCalled = false
        lastSavedNetwork = nil
        mockWifiNetworks = []
    }

    func saveNetwork(wifiNetwork: Windscribe.WifiNetwork) {
        saveNetworkCalled = true
        lastSavedNetwork = wifiNetwork
        if let index = mockWifiNetworks.firstIndex(where: { $0.SSID == wifiNetwork.SSID }) {
            mockWifiNetworks[index] = wifiNetwork
        } else {
            mockWifiNetworks.append(wifiNetwork)
        }
    }

    func saveFavourite(favourite: Windscribe.Favourite) -> any RxSwift.Disposable {
        guard var favourites = try? mockFavoritesSubject.value() else {
            return Disposables.create()
        }
        favourites[favourite.id] = favourite
        mockFavoritesSubject.onNext(favourites)
        return Disposables.create()
    }

    func getFavouriteListObservable() -> RxSwift.Observable<[Windscribe.Favourite]> {
        return mockFavoritesSubject
            .map { $0.count > 0 ? Array($0.values) : [] }
            .asObservable()
    }

    func getFavouriteList() -> [Windscribe.Favourite] {
        guard let favourites = try? mockFavoritesSubject.value() else {
            return []
        }
        return favourites
            .map { $0.value }
    }

    func removeFavourite(groupId: String) {
        guard var favourites = try? mockFavoritesSubject.value() else {
            return
        }
        favourites.removeValue(forKey: groupId)
        mockFavoritesSubject.onNext(favourites)
        return
    }

    func getCustomConfigObservable() -> RxSwift.Observable<[Windscribe.CustomConfig]> {
        return Observable.just([])
    }

    func getCustomConfig() -> [Windscribe.CustomConfig] {
        return []
    }

    func getCustomConfigObservable() -> RxSwift.Observable<[Windscribe.CustomConfig]> {
        return Observable.just([])
    }

    func getCustomConfigs() -> [Windscribe.CustomConfig] {
        return []
    }
}

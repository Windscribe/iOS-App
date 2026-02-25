//
//  MockLocalDatabase.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-02-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

@testable import Windscribe

class MockLocalDatabase: LocalDatabase {

    let sessionSubject = CurrentValueSubject<Windscribe.Session?, Never>(nil)
    let oldSessionSubject = CurrentValueSubject<Windscribe.OldSession?, Never>(nil)
    let notificationsSubject = CurrentValueSubject<[Windscribe.Notice], Never>([])
    let networksSubject = CurrentValueSubject<[Windscribe.WifiNetwork], Never>([])
    let readNoticesSubject = CurrentValueSubject<[Windscribe.ReadNotice], Never>([])
    let customConfigsSubject = CurrentValueSubject<[Windscribe.CustomConfig], Never>([])

    var mockServers: [Server]? = []
    let mockFavoritesSubject = CurrentValueSubject<[String: Favourite], Never>([:])
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
            networksSubject.send(mockWifiNetworks)
        }
    }
    var saveNetworkCalled = false
    var lastSavedNetwork: Windscribe.WifiNetwork?

    // PingData tracking
    var mockPingData: [Windscribe.PingData] = []

    // MyIP tracking (for migration tests)
    var mockMyIP: Windscribe.MyIP?

    // UnblockWgParams tracking
    var mockUnblockWgParams: [Windscribe.UnblockWgParamsObj] = []
    var saveUnblockWgParamsCalled = false

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

    func saveOpenVPNServerCredentials(credentials: Windscribe.OpenVPNServerCredentials) {

    }

    func getIKEv2ServerCredentials() -> Windscribe.IKEv2ServerCredentials? {
        return nil
    }

    func saveIKEv2ServerCredentials(credentials: Windscribe.IKEv2ServerCredentials) {

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

    func getNotificationsPublisher() -> AnyPublisher<[Windscribe.Notice], Never> {
        return notificationsSubject.eraseToAnyPublisher()
    }

    func saveNotifications(notifications: [Windscribe.Notice]) {
        saveNotificationsCalled = true
        notificationsToReturn = notifications
        // Trigger the subject to simulate Realm notification
        notificationsSubject.send(notifications)
    }

    func getReadNotices() -> [Windscribe.ReadNotice]? {
        return readNoticesSubject.value
    }

    func getReadNoticesPublisher() -> AnyPublisher<[Windscribe.ReadNotice], Never> {
        return readNoticesSubject.eraseToAnyPublisher()
    }

    func saveReadNotices(readNotices: [Windscribe.ReadNotice]) {
        readNoticesSubject.send(readNotices)
    }

    func getIpPublisher() -> AnyPublisher<Windscribe.MyIP?, Never> {
        Just<MyIP?>(nil).eraseToAnyPublisher()
    }

    func getIp() -> Windscribe.MyIP? {
        return mockMyIP
    }

    func saveIp(myip: Windscribe.MyIP) {

    }

    func getNetworksPublisher() -> AnyPublisher<[Windscribe.WifiNetwork], Never> {
        return networksSubject.eraseToAnyPublisher()
    }

    func removeNetwork(wifiNetwork: Windscribe.WifiNetwork) {
        mockWifiNetworks.removeAll { $0.SSID == wifiNetwork.SSID }
    }

    func addPingData(pingData: Windscribe.PingData) {
        // Remove existing ping data for the same IP if it exists
        mockPingData.removeAll { $0.ip == pingData.ip }
        // Add new ping data
        mockPingData.append(pingData)
    }

    func getAllPingData() -> [Windscribe.PingData] {
        return mockPingData
    }

    func saveCustomConfig(customConfig: Windscribe.CustomConfig) {
        var savedList = customConfigsSubject.value
        savedList.append(customConfig)
        customConfigsSubject.send(savedList)
    }

    func removeCustomConfig(fileId: String) {
        var savedList = customConfigsSubject.value
        savedList = savedList.filter { $0.id != fileId }
        customConfigsSubject.send(savedList)
    }

    func updateCustomConfigName(customConfigId: String, name: String) {
        var savedList = customConfigsSubject.value
        if var customConfig = savedList.first(where: { $0.id != customConfigId }) {
            customConfig.name = name
            savedList = savedList.filter { $0.id != customConfigId }
            savedList.append(customConfig)
            customConfigsSubject.send(savedList)
        }
    }

    func getCustomConfigPublisher() -> AnyPublisher<[CustomConfig], Never> {
        customConfigsSubject.eraseToAnyPublisher()
    }

    func getCustomConfigs() -> [Windscribe.CustomConfig] {
        customConfigsSubject.value
    }

    func getPorts(protocolType: String) -> [String]? {
        return []
    }

    func getRobertFilters() -> Windscribe.RobertFilters? {
        return nil
    }

    func saveRobertFilters(filters: Windscribe.RobertFilters) {

    }

    func saveLastConnetion(vpnConnection: Windscribe.VPNConnection) {

    }

    func toggleRobertRule(id: String) {}

    func updateCustomConfigCredentials(customConfigId: String, username: String, password: String) {}

    func saveOldSession() {
        saveOldSessionCalled = true
        guard let oldSession = sessionSubject.value else {
            return
        }
        oldSessionSubject.send(OldSession(session: oldSession))
    }

    func getOldSession() -> Windscribe.OldSession? {
        return oldSessionSubject.value
    }

    func getSessionPublisher() -> AnyPublisher<Windscribe.Session?, Never> {
        return sessionSubject.eraseToAnyPublisher()
    }

    func getSession() -> Windscribe.Session? {
        return sessionSubject.value
    }

    func saveSession(session: Windscribe.Session) {
        // Trigger the subject to simulate Realm notification
        sessionSubject.send(session)
    }

    func updateConnectionMode(value: String) {}

    func clean() {
        saveNetworkCalled = false
        lastSavedNetwork = nil
        mockWifiNetworks = []
        mockPingData = []
        mockUnblockWgParams = []
        saveUnblockWgParamsCalled = false
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

    func saveFavourite(favourite: Windscribe.Favourite) {
        var favourites = mockFavoritesSubject.value
        favourites[favourite.id] = favourite
        mockFavoritesSubject.send(favourites)

    }

    func getFavouriteListPublisher() -> AnyPublisher<[Windscribe.Favourite], Never> {
        return mockFavoritesSubject
            .map { $0.count > 0 ? Array($0.values) : [] }
            .eraseToAnyPublisher()
    }

    func getFavouriteList() -> [Windscribe.Favourite] {
        return mockFavoritesSubject.value
            .map { $0.value }
    }

    func removeFavourite(groupId: String) {
        var favourites = mockFavoritesSubject.value
        favourites.removeValue(forKey: groupId)
        mockFavoritesSubject.send(favourites)
        return
    }

    func saveUnblockWgParams(params: [Windscribe.UnblockWgParamsObj]) {
        saveUnblockWgParamsCalled = true
        mockUnblockWgParams = params
    }

    func getUnblockWgParams() -> [Windscribe.UnblockWgParamsObj] {
        return mockUnblockWgParams
    }
}

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
    let serverMachinesSubject = CurrentValueSubject<[Windscribe.ServerMachineObject], Never>([])

    var mockServers: [Server]? = []
    var mockLocations: [LocationObject]? = []
    var mockServerMachines: [ServerMachineObject]? = []
    let mockFavoritesSubject = CurrentValueSubject<[String: Favourite], Never>([:])
    // PortMap tracking
    var savePortMapCalled = false
    var saveSuggestedPortsCalled = false
    var portMapsToReturn: [Windscribe.PortMap]?
    var suggestedPortsToReturn: [Windscribe.SuggestedPorts]?

    // Notifications tracking
    var saveNotificationsCalled = false
    var notificationsToReturn: [Windscribe.Notice]?

    // StaticIP tracking
    var staticIPsToReturn: [Windscribe.StaticIP]?
    var saveStaticIPsCalled = false
    var deleteStaticIpsCalled = false
    var lastDeletedStaticIPsIgnoreList: [String]?

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
    var removeNetworkCalled = false

    // Robert filters tracking
    var mockRobertFilters: Windscribe.RobertFilters?
    var saveRobertFiltersCalled = false
    var lastSavedRobertFilters: Windscribe.RobertFilters?
    var toggleRobertRuleCalled = false
    var lastToggledRobertRuleId: String?
    var lastSavedNetwork: Windscribe.WifiNetwork?

    // PingData tracking
    var mockPingData: [Windscribe.PingData] = []

    // MyIP tracking (for migration tests)
    var mockMyIP: Windscribe.MyIP?

    // UnblockWgParams tracking
    var mockUnblockWgParams: [Windscribe.UnblockWgParamsObj] = []
    var saveUnblockWgParamsCalled = false

    // Migration tracking
    var migrateCalled = false
    var onMigrate: (() -> Void)?

    // Credentials tracking
    var mockOpenVPNCredentials: OpenVPNServerCredentials?
    var mockIKEv2Credentials: IKEv2ServerCredentials?

    func migrate() {
        migrateCalled = true
        onMigrate?()
    }

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

    func getLocations() -> [LocationObject]? {
        return mockLocations
    }

    func saveLocations(locations: [LocationObject]) {
        mockLocations = locations
    }

    func getServerMachines() -> [ServerMachineObject]? {
        return mockServerMachines
    }

    func saveServerMachines(serverMachines: [ServerMachineObject]) {
        mockServerMachines = serverMachines
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
        return mockOpenVPNCredentials
    }

    func getIKEv2ServerCredentials() -> Windscribe.IKEv2ServerCredentials? {
        return mockIKEv2Credentials
    }

    func clearOpenVPNServerCredentials() {
        mockOpenVPNCredentials = nil
    }

    func clearIKEv2ServerCredentials() {
        mockIKEv2Credentials = nil
    }

    func getPortMap() -> [Windscribe.PortMap]? {
        return portMapsToReturn
    }

    func savePortMap(portMap: [Windscribe.PortMap]) {
        savePortMapCalled = true
    }

    func saveSuggestedPorts(suggestedPorts: [Windscribe.SuggestedPorts]) {
        saveSuggestedPortsCalled = true
        suggestedPortsToReturn = suggestedPorts
    }

    func getSuggestedPorts() -> [Windscribe.SuggestedPorts]? {
        return suggestedPortsToReturn
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

    func getCustomConfigPublisher() -> AnyPublisher<[CustomConfig], Never> {
        customConfigsSubject.eraseToAnyPublisher()
    }

    func getCustomConfigs() -> [Windscribe.CustomConfig] {
        customConfigsSubject.value
    }

    var clearSessionFromRealmCalled = false
    func clearSessionFromRealm() {
        clearSessionFromRealmCalled = true
        sessionSubject.send(nil)
    }

    func getRobertFilters() -> Windscribe.RobertFilters? {
        return mockRobertFilters
    }

    func saveRobertFilters(filters: Windscribe.RobertFilters) {
        saveRobertFiltersCalled = true
        lastSavedRobertFilters = filters
        mockRobertFilters = filters
    }

    func toggleRobertRule(id: String) {
        toggleRobertRuleCalled = true
        lastToggledRobertRuleId = id
    }

    func getSession() -> Windscribe.Session? {
        return sessionSubject.value
    }

    func clean() {
        saveNetworkCalled = false
        lastSavedNetwork = nil
        mockWifiNetworks = []
        mockPingData = []
        mockUnblockWgParams = []
        saveUnblockWgParamsCalled = false
        mockOpenVPNCredentials = nil
        mockIKEv2Credentials = nil
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

    func removeFavourite(datacenterId: String) {
        var favourites = mockFavoritesSubject.value
        favourites.removeValue(forKey: datacenterId)
        mockFavoritesSubject.send(favourites)
    }

    func saveUnblockWgParams(params: [Windscribe.UnblockWgParamsObj]) {
        saveUnblockWgParamsCalled = true
        mockUnblockWgParams = params
    }

    func getUnblockWgParams() -> [Windscribe.UnblockWgParamsObj] {
        return mockUnblockWgParams
    }

    func getServerMachinesPublisher() -> AnyPublisher<[Windscribe.ServerMachineObject], Never> {
        serverMachinesSubject.eraseToAnyPublisher()
    }

    // MARK: - Helper Methods

    func reset() {
        sessionSubject.send(nil)
        oldSessionSubject.send(nil)
        notificationsSubject.send([])
        networksSubject.send([])
        readNoticesSubject.send([])
        mockServers = []
        mockLocations = []
        mockServerMachines = []
        mockFavoritesSubject.send([:])
        savePortMapCalled = false
        saveSuggestedPortsCalled = false
        portMapsToReturn = nil
        suggestedPortsToReturn = nil
        saveNotificationsCalled = false
        notificationsToReturn = nil
        staticIPsToReturn = nil
        saveStaticIPsCalled = false
        deleteStaticIpsCalled = false
        lastDeletedStaticIPsIgnoreList = nil
        mobilePlansToReturn = nil
        saveMobilePlansCalled = false
        mockWifiNetworks = []
        saveNetworkCalled = false
        removeNetworkCalled = false
        mockRobertFilters = nil
        saveRobertFiltersCalled = false
        lastSavedRobertFilters = nil
        toggleRobertRuleCalled = false
        lastToggledRobertRuleId = nil
        migrateCalled = false
        onMigrate = nil
    }
}

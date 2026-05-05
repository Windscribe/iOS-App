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
    let sessionSubject = CurrentValueSubject<SessionModel?, Never>(nil)
    let oldSessionSubject = CurrentValueSubject<SessionModel?, Never>(nil)
    let notificationsSubject = CurrentValueSubject<[NoticeModel], Never>([])
    let networksSubject = CurrentValueSubject<[WifiNetworkModel], Never>([])
    let readNoticesSubject = CurrentValueSubject<[Int], Never>([])
    let customConfigsSubject = CurrentValueSubject<[CustomConfigModel], Never>([])
    let serverMachinesSubject = CurrentValueSubject<[ServerMachineModel], Never>([])

    var mockServers: [LocationModel]? = []
    var mockLocations: [LocationModel]? = []
    var mockServerMachines: [ServerMachineModel]? = []
    let mockFavoritesSubject = CurrentValueSubject<[String: FavouriteModel], Never>([:])

    // PortMap tracking
    var savePortMapCalled = false
    var saveSuggestedPortsCalled = false
    var portMapsToReturn: [PortMapModel]?
    var suggestedPortsToReturn: [SuggestedPortsModel]?

    // Notifications tracking
    var saveNotificationsCalled = false
    var notificationsToReturn: [NoticeModel]?

    // StaticIP tracking
    var staticIPsToReturn: [StaticIPModel]?
    var saveStaticIPsCalled = false
    var deleteStaticIpsCalled = false
    var lastDeletedStaticIPsIgnoreList: [String]?

    // MobilePlan tracking
    var mobilePlansToReturn: [MobilePlanModel]?
    var saveMobilePlansCalled = false

    // WifiNetwork tracking
    var mockWifiNetworks: [WifiNetworkModel] = [] {
        didSet {
            networksSubject.send(mockWifiNetworks)
        }
    }
    var saveNetworkCalled = false
    var removeNetworkCalled = false

    // Robert filters tracking
    var mockRobertFilters: [RobertFilterModel]?
    var saveRobertFiltersCalled = false
    var lastSavedRobertFilters: [RobertFilterModel]?
    var toggleRobertRuleCalled = false
    var lastToggledRobertRuleId: String?
    var lastSavedNetwork: WifiNetworkModel?

    // PingData tracking
    var mockPingData: [PingDataModel] = []

    // MyIP tracking (for migration tests)
    var mockMyIP: Windscribe.MyIP?

    // UnblockWgParams tracking
    var mockUnblockWgParams: [UnblockWgParams] = []
    var saveUnblockWgParamsCalled = false

    // Migration tracking
    var migrateCalled = false
    var onMigrate: (() -> Void)?

    // Credentials tracking
    var mockOpenVPNCredentials: ServerCredentialsModel?
    var mockIKEv2Credentials: ServerCredentialsModel?

    func migrate() {
        migrateCalled = true
        onMigrate?()
    }

    func getMobilePlans() -> [MobilePlanModel]? {
        return mobilePlansToReturn
    }

    func saveMobilePlans(mobilePlansList: [MobilePlanModel]) {
        saveMobilePlansCalled = true
        mobilePlansToReturn = mobilePlansList
    }

    func getServers() -> [LocationModel]? {
        return mockServers
    }

    func getLocations() -> [LocationModel]? {
        return mockLocations
    }

    func saveLocations(locations: [LocationModel]) {
        mockLocations = locations
    }

    func getServerMachines() -> [ServerMachineModel]? {
        return mockServerMachines
    }

    func saveServerMachines(serverMachines: [ServerMachineModel]) {
        mockServerMachines = serverMachines
    }

    func getStaticIPs() -> [StaticIPModel]? {
        return staticIPsToReturn
    }

    func saveStaticIPs(staticIps: [StaticIPModel]) {
        saveStaticIPsCalled = true
        staticIPsToReturn = staticIps
    }

    func deleteStaticIps(ignore: [String]) {
        deleteStaticIpsCalled = true
        lastDeletedStaticIPsIgnoreList = ignore
    }

    func getOpenVPNServerCredentials() -> ServerCredentialsModel? {
        return mockOpenVPNCredentials
    }

    func getIKEv2ServerCredentials() -> ServerCredentialsModel? {
        return mockIKEv2Credentials
    }

    func clearOpenVPNServerCredentials() {
        mockOpenVPNCredentials = nil
    }

    func clearIKEv2ServerCredentials() {
        mockIKEv2Credentials = nil
    }

    func getPortMap() -> [PortMapModel]? {
        return portMapsToReturn
    }

    func savePortMap(portMap: [PortMapModel]) {
        savePortMapCalled = true
    }

    func saveSuggestedPorts(suggestedPorts: [SuggestedPortsModel]) {
        saveSuggestedPortsCalled = true
        suggestedPortsToReturn = suggestedPorts
    }

    func getSuggestedPorts() -> [SuggestedPortsModel]? {
        return suggestedPortsToReturn
    }

    func getNotificationsPublisher() -> AnyPublisher<[NoticeModel], Never> {
        return notificationsSubject.eraseToAnyPublisher()
    }

    func getNotifications() -> [NoticeModel] {
        return notificationsToReturn ?? []
    }

    func saveNotifications(notifications: [NoticeModel]) {
        saveNotificationsCalled = true
        notificationsToReturn = notifications
        notificationsSubject.send(notifications)
    }

    func getReadNotices() -> [Int]? {
        return readNoticesSubject.value
    }

    func getReadNoticesPublisher() -> AnyPublisher<[Int], Never> {
        return readNoticesSubject.eraseToAnyPublisher()
    }

    func saveReadNotices(readNotices: [Int]) {
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

    func getNetworksPublisher() -> AnyPublisher<[WifiNetworkModel], Never> {
        return networksSubject.eraseToAnyPublisher()
    }

    func getNetworks() -> [WifiNetworkModel] {
        return mockWifiNetworks
    }

    func removeNetwork(wifiNetwork: WifiNetworkModel) {
        mockWifiNetworks.removeAll { $0.SSID == wifiNetwork.SSID }
    }

    func addPingData(pingData: PingDataModel) {
        mockPingData.removeAll { $0.ip == pingData.ip }
        mockPingData.append(pingData)
    }

    func getAllPingData() -> [PingDataModel] {
        return mockPingData
    }

    func saveCustomConfig(customConfig: CustomConfigModel) {
        var savedList = customConfigsSubject.value
        savedList.append(customConfig)
        customConfigsSubject.send(savedList)
    }

    func removeCustomConfig(fileId: String) {
        var savedList = customConfigsSubject.value
        savedList = savedList.filter { $0.id != fileId }
        customConfigsSubject.send(savedList)
    }

    func getCustomConfigPublisher() -> AnyPublisher<[CustomConfigModel], Never> {
        customConfigsSubject.eraseToAnyPublisher()
    }

    func getCustomConfigs() -> [CustomConfigModel] {
        customConfigsSubject.value
    }

    var clearSessionFromRealmCalled = false
    func clearSessionFromRealm() {
        clearSessionFromRealmCalled = true
        sessionSubject.send(nil)
    }

    func getRobertFilters() -> [RobertFilterModel]? {
        return mockRobertFilters
    }

    func saveRobertFilters(filters: [RobertFilterModel]) {
        saveRobertFiltersCalled = true
        lastSavedRobertFilters = filters
        mockRobertFilters = filters
    }

    func toggleRobertRule(id: String) {
        toggleRobertRuleCalled = true
        lastToggledRobertRuleId = id
    }

    func getSession() -> SessionModel? {
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

    func saveNetwork(wifiNetwork: WifiNetworkModel) {
        saveNetworkCalled = true
        lastSavedNetwork = wifiNetwork
        if let index = mockWifiNetworks.firstIndex(where: { $0.SSID == wifiNetwork.SSID }) {
            mockWifiNetworks[index] = wifiNetwork
        } else {
            mockWifiNetworks.append(wifiNetwork)
        }
    }

    func saveFavourite(favourite: FavouriteModel) {
        var favourites = mockFavoritesSubject.value
        favourites[favourite.id] = favourite
        mockFavoritesSubject.send(favourites)
    }

    func getFavouriteListPublisher() -> AnyPublisher<[FavouriteModel], Never> {
        return mockFavoritesSubject
            .map { $0.count > 0 ? Array($0.values) : [] }
            .eraseToAnyPublisher()
    }

    func getFavouriteList() -> [FavouriteModel] {
        return mockFavoritesSubject.value.map { $0.value }
    }


    func removeFavourite(datacenterId: String) {
        var favourites = mockFavoritesSubject.value
        favourites.removeValue(forKey: datacenterId)
        mockFavoritesSubject.send(favourites)
    }

    func saveUnblockWgParams(params: [UnblockWgParams]) {
        saveUnblockWgParamsCalled = true
        mockUnblockWgParams = params
    }

    func getUnblockWgParams() -> [UnblockWgParams] {
        return mockUnblockWgParams
    }

    func getServerMachinesPublisher() -> AnyPublisher<[ServerMachineModel], Never> {
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

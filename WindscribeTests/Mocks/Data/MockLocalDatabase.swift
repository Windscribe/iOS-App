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

    var mockServers: [Server]? = []
    // PortMap tracking
    var savePortMapCalled = false
    var saveSuggestedPortsCalled = false
    var portMapsToReturn: [Windscribe.PortMap]?

    func migrate() {}

    func getSession() -> Observable<Windscribe.Session?> {
        return sessionSubject.asObservable()
    }

    func getSessionSync() -> Windscribe.Session? {
        return nil
    }

    func saveSession(session: Windscribe.Session) -> Disposable {
        return Disposables.create()
    }

    func getMobilePlans() -> [Windscribe.MobilePlan]? {
        return []
    }

    func saveMobilePlans(mobilePlansList: [Windscribe.MobilePlan]) {}

    func getServers() -> [Windscribe.Server]? {
        return mockServers
    }

    func getServersObservable() -> Observable<[Windscribe.Server]> {
        return Observable.just([])
    }

<<<<<<< ours:WindscribeTests/Mocks/MockLocalDatabase.swift
    func saveServers(servers: [Windscribe.Server]) {}
=======
    func saveServers(servers: [Windscribe.Server]) async {
        mockServers = servers
    }
>>>>>>> theirs:WindscribeTests/Mocks/Data/MockLocalDatabase.swift

    func getStaticIPs() -> [Windscribe.StaticIP]? {
        return []
    }

    func saveStaticIPs(staticIps: [Windscribe.StaticIP]) {}

    func deleteStaticIps(ignore: [String]) {}

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

    func getNotifications() -> [Windscribe.Notice]? {
        return []
    }

    func getNotificationsObservable() -> Observable<[Windscribe.Notice]> {
        return Observable.just([])
    }

    func saveNotifications(notifications: [Windscribe.Notice]) {}

    func getReadNotices() -> [Windscribe.ReadNotice]? {
        return []
    }

    func getReadNoticesObservable() -> Observable<[Windscribe.ReadNotice]> {
        return Observable.just([])
    }

    func saveReadNotices(readNotices: [Windscribe.ReadNotice]) {}

    func getIp() -> Observable<Windscribe.MyIP?> {
        return Observable.just(nil)
    }

    func saveIp(myip: Windscribe.MyIP) -> Disposable {
        return Disposables.create()
    }

    func getNetworks() -> Observable<[Windscribe.WifiNetwork]> {
        return Observable.just([])
    }


    func removeNetwork(wifiNetwork: Windscribe.WifiNetwork) {}

    func addPingData(pingData: Windscribe.PingData) {}

    func getAllPingData() -> [Windscribe.PingData] {
        return []
    }

    func saveCustomConfig(customConfig: Windscribe.CustomConfig) -> Disposable {
        return Disposables.create()
    }

    func removeCustomConfig(fileId: String) {}

    func getCustomConfig() -> Observable<[Windscribe.CustomConfig]> {
        return Observable.just([])
    }

    func getPorts(protocolType: String) -> [String]? {
        return []
    }

    func getRobertFilters() -> Windscribe.RobertFilters? {
        return nil
    }

    func saveRobertFilters(filters: Windscribe.RobertFilters) -> Disposable {
        return Disposables.create()
    }

    func getLastConnection() -> Observable<Windscribe.VPNConnection?> {
        return Observable.just(nil)
    }

    func saveLastConnetion(vpnConnection: Windscribe.VPNConnection) -> Disposable {
        return Disposables.create()
    }

    func toggleRobertRule(id: String) {}

    func updateNetworkWithPreferredProtocolSwitch(network: Windscribe.WifiNetwork, status: Bool) {}

    func updateTrustNetwork(network: Windscribe.WifiNetwork, status: Bool) {}

    func updateWifiNetwork(network: Windscribe.WifiNetwork, property: String, value: Any) {}

    func updateWifiNetwork(network: Windscribe.WifiNetwork, properties: [String: Any]) {}

    func updateNetworkDismissCount(network: Windscribe.WifiNetwork, dismissCount: Int) {}

    func updateNetworkDontAskAgainForPreferredProtocol(network: Windscribe.WifiNetwork, status: Bool) {}

    func updateCustomConfigName(customConfigId: String, name: String) {}

    func updateCustomConfigCredentials(customConfigId: String, username: String, password: String) {}

    func saveOldSession() {}

    func getOldSession() -> Windscribe.OldSession? {
        return nil
    }

    func saveBestNode(node: Windscribe.BestNode) -> Disposable {
        return Disposables.create()
    }

    func getBestNode() -> [Windscribe.BestNode]? {
        return []
    }

    func updateConnectionMode(value: String) {}

    func getCustomConfigs() -> [Windscribe.CustomConfig] {
        return []
    }

    func clean() {}

    func getGroups() -> [Windscribe.Group]? {
        return []
    }

    func getNetworksSync() -> [Windscribe.WifiNetwork]? {
        return []
    }

    func getPublishedNetworks() -> AnyPublisher<[Windscribe.WifiNetwork], Never> {
        return Just([]).eraseToAnyPublisher()
    }

    func saveNetwork(wifiNetwork: Windscribe.WifiNetwork) {
        // Mock implementation - no-op
    }

    func saveFavourite(favourite: Windscribe.Favourite) -> any RxSwift.Disposable {
        return Disposables.create()
    }

    func getFavouriteListObservable() -> RxSwift.Observable<[Windscribe.Favourite]> {
        return Observable.just([])
    }

    func getFavouriteList() -> [Windscribe.Favourite] {
        return []
    }

    func removeFavourite(groupId: String) {
        // Mock implementation - no-op
    }
}

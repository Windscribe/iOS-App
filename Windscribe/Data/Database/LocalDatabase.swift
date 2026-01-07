//
//  LocalDatabase.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-25.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Combine

protocol LocalDatabase {
    func migrate()

    // MARK: After Modelization of Database
    func getServers() -> [Server]?
    func saveServers(servers: [Server])

    func getSession() -> Observable<Session?>
    func getSessionSync() -> Session?
    func saveSession(session: Session)

    // MARK: Before Modelization of Databas)
    func getMobilePlans() -> [MobilePlan]?
    func saveMobilePlans(mobilePlansList: [MobilePlan])
    func getStaticIPs() -> [StaticIP]?
    func saveStaticIPs(staticIps: [StaticIP])
    func deleteStaticIps(ignore: [String])
    func getOpenVPNServerCredentials() -> OpenVPNServerCredentials?
    func saveOpenVPNServerCredentials(credentials: OpenVPNServerCredentials) -> Disposable
    func getIKEv2ServerCredentials() -> IKEv2ServerCredentials?
    func saveIKEv2ServerCredentials(credentials: IKEv2ServerCredentials) -> Disposable
    func getPortMap() -> [PortMap]?
    func savePortMap(portMap: [PortMap])
    func saveSuggestedPorts(suggestedPorts: [SuggestedPorts])
    func getSuggestedPorts() -> [SuggestedPorts]?
    func getNotifications() -> [Notice]?
    func getNotificationsObservable() -> Observable<[Notice]>
    func saveNotifications(notifications: [Notice]) async
    func getReadNotices() -> [ReadNotice]?
    func getReadNoticesObservable() -> Observable<[ReadNotice]>
    func saveReadNotices(readNotices: [ReadNotice])

    /// DEPRECATED - Issue #911: Use Preferences.getCurrentIpAddressObservable() instead.
    /// This method is kept for migration support only. Will be removed in v3.10.0+
    @available(*, deprecated, message: "Use Preferences.getCurrentIpAddressObservable() instead")
    func getIp() -> Observable<MyIP?>

    /// DEPRECATED - Issue #911: Use Preferences.getCurrentIpAddress() instead.
    /// This method is kept for migration support only. Will be removed in v3.10.0+
    @available(*, deprecated, message: "Use Preferences.getCurrentIpAddress() instead")
    func getIpSync() -> MyIP?

    /// DEPRECATED - Issue #911: Use Preferences.saveCurrentIpAddress(ip:) instead.
    /// This method is kept for migration support only. Will be removed in v3.10.0+
    @available(*, deprecated, message: "Use Preferences.saveCurrentIpAddress(ip:) instead")
    func saveIp(myip: MyIP) -> Disposable

    func getNetworks() -> Observable<[WifiNetwork]>
    func saveNetwork(wifiNetwork: WifiNetwork)
    func removeNetwork(wifiNetwork: WifiNetwork)
    func addPingData(pingData: PingData)
    func getAllPingData() -> [PingData]
    func saveCustomConfig(customConfig: CustomConfig)
    func removeCustomConfig(fileId: String)
    func getCustomConfig() -> Observable<[CustomConfig]>
    func getPorts(protocolType: String) -> [String]?
    func getRobertFilters() -> RobertFilters?
    func saveRobertFilters(filters: RobertFilters) -> Disposable
    func getLastConnection() -> Observable<VPNConnection?>
    func saveLastConnetion(vpnConnection: VPNConnection) -> Disposable

    func saveFavourite(favourite: Favourite) -> Disposable
    func getFavouriteListObservable() -> Observable<[Favourite]>
    func getFavouriteList() -> [Favourite]
    func removeFavourite(groupId: String)

    func toggleRobertRule(id: String)
    func updateCustomConfigName(customConfigId: String, name: String)
    func updateCustomConfigCredentials(customConfigId: String, username: String, password: String)
    func saveOldSession()
    func getOldSession() -> OldSession?
    func saveBestNode(node: BestNode) -> Disposable
    func getBestNode() -> [BestNode]?
    func getCustomConfigs() -> [CustomConfig]
    func clean()
}

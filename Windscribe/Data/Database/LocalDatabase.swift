//
//  LocalDatabase.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-25.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

protocol LocalDatabase {
    func migrate()

    // MARK: After Modelization of Database
    func getServers() -> [Server]?
    func saveServers(servers: [Server])

    func getSessionPublisher() -> AnyPublisher<Session?, Never>
    func getSession() -> Session?
    func saveSession(session: Session)

    // MARK: Before Modelization of Databas)
    func getMobilePlans() -> [MobilePlan]?
    func saveMobilePlans(mobilePlansList: [MobilePlan])
    func getStaticIPs() -> [StaticIP]?
    func saveStaticIPs(staticIps: [StaticIP])
    func deleteStaticIps(ignore: [String])
    func getOpenVPNServerCredentials() -> OpenVPNServerCredentials?
    func saveOpenVPNServerCredentials(credentials: OpenVPNServerCredentials)
    func getIKEv2ServerCredentials() -> IKEv2ServerCredentials?
    func saveIKEv2ServerCredentials(credentials: IKEv2ServerCredentials)
    func getPortMap() -> [PortMap]?
    func savePortMap(portMap: [PortMap])
    func saveSuggestedPorts(suggestedPorts: [SuggestedPorts])
    func getSuggestedPorts() -> [SuggestedPorts]?
    func getNotificationsPublisher() -> AnyPublisher<[Notice], Never>
    func saveNotifications(notifications: [Notice])
    func getReadNotices() -> [ReadNotice]?
    func getReadNoticesPublisher() -> AnyPublisher<[ReadNotice], Never>
    func saveReadNotices(readNotices: [ReadNotice])

    /// DEPRECATED - Issue #911: Use Preferences.getCurrentIpAddressPublisher() instead.
    /// This method is kept for migration support only. Will be removed in v3.10.0+
    @available(*, deprecated, message: "Use Preferences.getCurrentIpAddressPublisher() instead")
    func getIpPublisher() -> AnyPublisher<MyIP?, Never>

    /// DEPRECATED - Issue #911: Use Preferences.getCurrentIpAddress() instead.
    /// This method is kept for migration support only. Will be removed in v3.10.0+
    @available(*, deprecated, message: "Use Preferences.getCurrentIpAddress() instead")
    func getIp() -> MyIP?

    /// DEPRECATED - Issue #911: Use Preferences.saveCurrentIpAddress(ip:) instead.
    /// This method is kept for migration support only. Will be removed in v3.10.0+
    @available(*, deprecated, message: "Use Preferences.saveCurrentIpAddress(ip:) instead")
    func saveIp(myip: MyIP)

    func getNetworksPublisher() -> AnyPublisher<[WifiNetwork], Never>
    func saveNetwork(wifiNetwork: WifiNetwork)
    func removeNetwork(wifiNetwork: WifiNetwork)
    func addPingData(pingData: PingData)
    func getAllPingData() -> [PingData]
    func saveCustomConfig(customConfig: CustomConfig)
    func removeCustomConfig(fileId: String)
    func getCustomConfigPublisher() -> AnyPublisher<[CustomConfig], Never>
    func getRobertFilters() -> RobertFilters?
    func saveRobertFilters(filters: RobertFilters)

    func saveFavourite(favourite: Favourite)
    func getFavouriteListPublisher() -> AnyPublisher<[Favourite], Never>
    func getFavouriteList() -> [Favourite]
    func removeFavourite(groupId: String)

    func toggleRobertRule(id: String)
    func saveOldSession()
    func getOldSession() -> OldSession?
    func getCustomConfigs() -> [CustomConfig]

    func saveUnblockWgParams(params: [UnblockWgParamsObj])
    func getUnblockWgParams() -> [UnblockWgParamsObj]

    func clean()
}

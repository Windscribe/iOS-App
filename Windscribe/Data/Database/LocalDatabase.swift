//
//  LocalDatabase.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-25.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol LocalDatabase {
    func migrate()

    // MARK: After Modelization of Database
    func getServers() -> [LocationModel]? // Needs to be kept if the user migrates and has no Locations yet

    // Sessions live in the Keychain via SessionKeychainStore. The Realm-backed
    // getSession + clearSessionFromRealm exist solely so MigrationRepository
    // can read any pre-keychain session row out of Realm and then wipe it.
    func getSession() -> SessionModel?
    func clearSessionFromRealm()

    // MARK: New Server Architecture
    func getLocations() -> [LocationModel]?
    func saveLocations(locations: [LocationModel])

    func getServerMachines() -> [ServerMachineModel]?
    func getServerMachinesPublisher() -> AnyPublisher<[ServerMachineModel], Never>
    func saveServerMachines(serverMachines: [ServerMachineModel])

    // MARK: Before Modelization of Database
    func getMobilePlans() -> [MobilePlanModel]?
    func saveMobilePlans(mobilePlansList: [MobilePlanModel])
    func getStaticIPs() -> [StaticIPModel]?
    func saveStaticIPs(staticIps: [StaticIPModel])
    func deleteStaticIps(ignore: [String])

    // OpenVPN/IKEv2 server credentials live in the Keychain via Preferences.
    // The Realm-backed get + clear methods exist solely so MigrationRepository
    // can copy any pre-keychain credentials out of Realm and wipe the rows.
    func getOpenVPNServerCredentials() -> ServerCredentialsModel?
    func clearOpenVPNServerCredentials()
    func getIKEv2ServerCredentials() -> ServerCredentialsModel?
    func clearIKEv2ServerCredentials()

    func getPortMap() -> [PortMapModel]?
    func savePortMap(portMap: [PortMapModel])
    func saveSuggestedPorts(suggestedPorts: [SuggestedPortsModel])
    func getSuggestedPorts() -> [SuggestedPortsModel]?
    func getNotificationsPublisher() -> AnyPublisher<[NoticeModel], Never>
    func getNotifications() -> [NoticeModel]
    func saveNotifications(notifications: [NoticeModel])
    func getReadNotices() -> [Int]?
    func getReadNoticesPublisher() -> AnyPublisher<[Int], Never>
    func saveReadNotices(readNotices: [Int])

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

    func getNetworksPublisher() -> AnyPublisher<[WifiNetworkModel], Never>
    func getNetworks() -> [WifiNetworkModel]
    func saveNetwork(wifiNetwork: WifiNetworkModel)
    func removeNetwork(wifiNetwork: WifiNetworkModel)
    func addPingData(pingData: PingDataModel)
    func getAllPingData() -> [PingDataModel]
    func saveCustomConfig(customConfig: CustomConfigModel)
    func removeCustomConfig(fileId: String)
    func getCustomConfigPublisher() -> AnyPublisher<[CustomConfigModel], Never>
    func getRobertFilters() -> [RobertFilterModel]?
    func saveRobertFilters(filters: [RobertFilterModel])

    func saveFavourite(favourite: FavouriteModel)
    func getFavouriteListPublisher() -> AnyPublisher<[FavouriteModel], Never>
    func getFavouriteList() -> [FavouriteModel]
    func removeFavourite(datacenterId: String)

    func toggleRobertRule(id: String)
    func getCustomConfigs() -> [CustomConfigModel]

    func saveUnblockWgParams(params: [UnblockWgParams])
    func getUnblockWgParams() -> [UnblockWgParams]

    func clean()
}

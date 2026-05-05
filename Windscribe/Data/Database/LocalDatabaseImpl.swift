//
//  LocalDatabaseImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-25.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import Combine

class LocalDatabaseImpl: LocalDatabase {
    let logger: FileLogger
    let cleanSubject = PassthroughSubject<Void, Never>()
    let preferences: Preferences

    init(logger: FileLogger, preferences: Preferences) {
        self.logger = logger
        self.preferences = preferences
    }

    // MARK: - After Modelization of Database
    func getServers() -> [LocationModel]? {
        return getRealmObjectList(type: Server.self)?.map { $0.getLocationModel() }
    }

    func getSession() -> SessionModel? {
        return getRealmObject(type: Session.self)?.getModel()
    }

    func clearSessionFromRealm() {
        if let object = getRealmObject(type: Session.self) {
            deleteRealmObject(object: object)
        }
    }

    // MARK: - Server V2 Architecture
    func getLocations() -> [LocationModel]? {
        return getRealmObjectList(type: LocationObject.self)?.map { LocationModel(from: $0) }
    }

    func saveLocations(locations: [LocationModel]) {
        let objects = locations.map { LocationObject(from: $0) }
        return updateRealmObjects(objects: objects)
    }

    func getServerMachines() -> [ServerMachineModel]? {
        return getRealmObjectList(type: ServerMachineObject.self)?.map { ServerMachineModel(from: $0) }
    }

    func getServerMachinesPublisher() -> AnyPublisher<[ServerMachineModel], Never> {
        return getModelArrayPublisher(type: ServerMachineObject.self) { ServerMachineModel(from: $0) }
    }

    func saveServerMachines(serverMachines: [ServerMachineModel]) {
        let objects = serverMachines.map { ServerMachineObject(from: $0) }
        return updateRealmObjects(objects: objects)
    }

    // MARK: - Before Modelization of Database

    func getMobilePlans() -> [MobilePlanModel]? {
        return getRealmObjectList(type: MobilePlan.self)?.map { $0.getModel() }
    }

    func saveMobilePlans(mobilePlansList: [MobilePlanModel]) {
        let objects = mobilePlansList.map { MobilePlan(from: $0) }
        return updateRealmObjects(objects: objects)
    }

    func getCustomConfigs() -> [CustomConfigModel] {
        return getRealmObjectList(type: CustomConfig.self)?.map { $0.getModel() } ?? []
    }

    func saveCustomConfig(customConfig: CustomConfigModel) {
        let obj = customConfig.getRealmObject()
        do {
            let realm = try Realm()
            try realm.safeWrite {
                realm.add(obj, update: .modified)
            }
        } catch {
            logger.logE("LocalDatabaseImpl", "Failed to save custom config: \(error.localizedDescription)")
        }
    }

    func removeCustomConfig(fileId: String) {
        if let object = getRealmObject(type: CustomConfig.self, primaryKey: fileId) {
            deleteRealmObject(object: object)
        }
    }

    func getCustomConfigPublisher() -> AnyPublisher<[CustomConfigModel], Never> {
        return getModelArrayPublisher(type: CustomConfig.self) { $0.getModel() }
    }

    func getStaticIPs() -> [StaticIPModel]? {
        return getRealmObjectList(type: StaticIP.self)?.map { $0.getModel() }
    }

    func saveStaticIPs(staticIps: [StaticIPModel]) {
        let objects = staticIps.map { StaticIP(from: $0) }
        return updateRealmObjects(objects: objects)
    }

    func deleteStaticIps(ignore: [String]) {
        if let objects = getRealmObjectList(type: StaticIP.self) {
            for stat in objects {
                if stat.isInvalidated == false && !ignore.contains(stat.staticIP) {
                    deleteRealmObject(object: stat)
                }
            }
        }
    }

    func getOpenVPNServerCredentials() -> ServerCredentialsModel? {
        return getRealmObject(type: OpenVPNServerCredentials.self)?.getModel()
    }

    func getIKEv2ServerCredentials() -> ServerCredentialsModel? {
        return getRealmObject(type: IKEv2ServerCredentials.self)?.getModel()
    }

    func clearOpenVPNServerCredentials() {
        if let object = getRealmObject(type: OpenVPNServerCredentials.self) {
            deleteRealmObject(object: object)
        }
    }

    func clearIKEv2ServerCredentials() {
        if let object = getRealmObject(type: IKEv2ServerCredentials.self) {
            deleteRealmObject(object: object)
        }
    }

    func getPortMap() -> [PortMapModel]? {
        return getRealmObjectList(type: PortMap.self)?.map { $0.getModel() }
    }

    func getSuggestedPorts() -> [SuggestedPortsModel]? {
        return getRealmObjectList(type: SuggestedPorts.self)?.map { $0.getModel() }
    }

    func saveSuggestedPorts(suggestedPorts: [SuggestedPortsModel]) {
        let objects = suggestedPorts.map { SuggestedPorts(from: $0) }
        return updateRealmObjects(objects: objects)
    }

    func savePortMap(portMap: [PortMapModel]) {
        let objects = portMap.map { PortMap(from: $0) }
        return updateRealmObjects(objects: objects)
    }

    func getNotificationsPublisher() -> AnyPublisher<[NoticeModel], Never> {
        return getModelArrayPublisher(type: Notice.self) { $0.getModel() }
    }

    func getNotifications() -> [NoticeModel] {
        return getRealmObjectList(type: Notice.self)?.map { $0.getModel() } ?? []
    }

    func saveNotifications(notifications: [NoticeModel]) {
        do {
            let realm = try Realm()
            try realm.safeWrite {
                // Delete all existing notifications first to remove stale ones
                let existingNotifications = realm.objects(Notice.self)
                realm.delete(existingNotifications)

                // Add all new notifications from API
                for model in notifications {
                    let obj = Notice(from: model)
                    realm.add(obj, update: .modified)
                }
            }
        } catch {
            logger.logE("LocalDatabaseImpl", "Failed to save notifications: \(error.localizedDescription)")
        }
    }

    func getReadNoticesPublisher() -> AnyPublisher<[Int], Never> {
        return getModelArrayPublisher(type: ReadNotice.self) { $0.id }
    }

    func getReadNotices() -> [Int]? {
        return getRealmObjectList(type: ReadNotice.self)?.map { $0.id }
    }

    func saveReadNotices(readNotices: [Int]) {
        let objects = readNotices.map { ReadNotice(noticeID: $0) }
        return updateRealmObjects(objects: objects)
    }

    /// DEPRECATED - Issue #911: Use Preferences.getCurrentIpAddressPublisher() instead.
    /// This method is kept for migration support only. Will be removed in v3.10.0+
    @available(*, deprecated, message: "Use Preferences.getCurrentIpAddressPublisher() instead")
    func getIpPublisher() -> AnyPublisher<MyIP?, Never> {
        return getSafeRealmObjectPublisher(type: MyIP.self)
    }

    /// DEPRECATED - Issue #911: Use Preferences.getCurrentIpAddress() instead.
    /// This method is kept for migration support only. Will be removed in v3.10.0+
    @available(*, deprecated, message: "Use Preferences.getCurrentIpAddress() instead")
    func getIp() -> MyIP? {
        return getRealmObject(type: MyIP.self)
    }

    /// DEPRECATED - Issue #911: Use Preferences.saveCurrentIpAddress(ip:) instead.
    /// This method is kept for migration support only. Will be removed in v3.10.0+
    @available(*, deprecated, message: "Use Preferences.saveCurrentIpAddress(ip:) instead")
    func saveIp(myip: MyIP) {
        return updateRealmObject(object: myip)
    }

    func getNetworksPublisher() -> AnyPublisher<[WifiNetworkModel], Never> {
        return getModelArrayPublisher(type: WifiNetwork.self) { WifiNetworkModel(from: $0) }
    }

    func getNetworks() -> [WifiNetworkModel] {
        return getRealmObjectList(type: WifiNetwork.self)?.map { WifiNetworkModel(from: $0) } ?? []
    }

    func saveNetwork(wifiNetwork: WifiNetworkModel) {
        let obj = WifiNetwork(from: wifiNetwork)
        return updateRealmObject(object: obj)
    }

    func removeNetwork(wifiNetwork: WifiNetworkModel) {
        if let managedNetwork = getRealmObject(type: WifiNetwork.self, primaryKey: wifiNetwork.SSID) {
            deleteRealmObject(object: managedNetwork)
        }
    }

    func getAllPingData() -> [PingDataModel] {
        return getRealmObjectList(type: PingData.self)?.map { PingDataModel(from: $0) } ?? []
    }

    func addPingData(pingData: PingDataModel) {
        do {
            let realm = try Realm()
            let obj = PingData(from: pingData)
            try realm.safeWrite {
                realm.add(obj, update: .modified)
            }
        } catch {
            logger.logE("LocalDatabaseImpl", "Failed to add ping data: \(error.localizedDescription)")
        }
    }

    func getRobertFilters() -> [RobertFilterModel]? {
        return getRealmObject(type: RobertFilters.self)?.filters.map { $0.getModel() }
    }

    func saveRobertFilters(filters: [RobertFilterModel]) {
        let robertFilters = RobertFilters(from: filters)
        return updateRealmObject(object: robertFilters)
    }

    func saveFavourite(favourite: FavouriteModel) {
        let obj = Favourite(from: favourite)
        return updateRealmObject(object: obj)
    }

    func getFavouriteListPublisher() -> AnyPublisher<[FavouriteModel], Never> {
        return getModelArrayPublisher(type: Favourite.self) { $0.getModel() }
    }

    func getFavouriteList() -> [FavouriteModel] {
        return getRealmObjectList(type: Favourite.self)?.map { $0.getModel() } ?? []
    }

    func removeFavourite(datacenterId: String) {
        if let object = getRealmObject(type: Favourite.self, primaryKey: datacenterId) {
            deleteRealmObject(object: object)
        }
    }

    func clean() {
        let realm = try? Realm()

        cleanSubject.send(())
        guard let realm = realm else { return }

        try? realm.write {
            for objectSchema in realm.schema.objectSchema {
                let objectType = doNotDeleteObjects.first(where: { $0 == objectSchema.className })
                if objectType == nil {
                    if let objectSchema = realm.schema[objectSchema.className],
                       let objectType = objectSchema.objectClass as? Object.Type {
                        let objects = realm.objects(objectType)
                        realm.delete(objects)
                    }
                } else {
                    logger.logD("LocalDatabase", "Skipping deletion of \(String(describing: objectSchema.className))")
                }
            }
        }
    }

    func saveUnblockWgParams(params: [UnblockWgParams]) {
        let objects = params.map { UnblockWgParamsObj(from: $0) }
        return updateRealmObjects(objects: objects)
    }

    func getUnblockWgParams() -> [UnblockWgParams] {
        return getRealmObjectList(type: UnblockWgParamsObj.self)?.map { $0.getModel() } ?? []
    }

    func toggleRobertRule(id: String) {
        guard let filters = getRealmObject(type: RobertFilters.self) else { return }
        let o = filters.filters.first {
            $0.id == id
        }
        guard let filter = o else { return }
        do {
            let realm = try Realm()
            try realm.safeWrite {
                if filter.status == 0 {
                    filter.status = 1
                    filter.enabled = true
                } else {
                    filter.status = 0
                    filter.enabled = false
                }
            }
        } catch {
            fatalError("")
        }
    }

    func updateTrustNetwork(network: WifiNetwork, status: Bool) {
        let updatedNetwork = network

        do {
            let realm = try Realm()
            try realm.safeWrite {
                updatedNetwork.preferredProtocolStatus = false
                updatedNetwork.status = !status
            }
        } catch {
            fatalError("")
        }
    }

    func updateWifiNetwork(network: WifiNetwork, properties: [String: Any]) {
        let updatedNetwork = network
        do {
            let realm = try Realm()
            try realm.safeWrite {
                for (property, value) in properties {
                    switch property {
                    case Fields.WifiNetwork.trustStatus:
                        updatedNetwork.status = (value as? Bool) ?? false
                    case Fields.WifiNetwork.preferredPort:
                        updatedNetwork.preferredPort = (value as? String) ?? ""
                    case Fields.WifiNetwork.preferredProtocol:
                        updatedNetwork.preferredProtocol = (value as? String) ?? ""
                    case Fields.WifiNetwork.preferredProtocolStatus:
                        updatedNetwork.preferredProtocolStatus = (value as? Bool) ?? false
                    case Fields.WifiNetwork.dontAskAgainForPreferredProtocol:
                        updatedNetwork.dontAskAgainForPreferredProtocol = (value as? Bool) ?? false
                    case Fields.protocolType:
                        updatedNetwork.protocolType = (value as? String) ?? ""
                    case Fields.port:
                        updatedNetwork.port = (value as? String) ?? ""
                    default:
                        continue
                    }
                }
            }
        } catch {
            fatalError("")
        }
    }

    func updateWifiNetwork(network: WifiNetwork, property: String, value: Any) {
        updateWifiNetwork(network: network, properties: [property: value])
    }

    func updateNetworkDismissCount(network: WifiNetwork, dismissCount: Int) {
        let updated = network
        do {
            let realm = try Realm()
            try realm.safeWrite {
                updated.popupDismissCount = dismissCount
            }
        } catch {
            fatalError("")
        }
    }

    func updateNetworkDontAskAgainForPreferredProtocol(network: WifiNetwork, status: Bool) {
        let updated = network
        do {
            let realm = try Realm()
            try realm.safeWrite {
                updated.dontAskAgainForPreferredProtocol = status
            }
        } catch {
            fatalError("")
        }
    }
}

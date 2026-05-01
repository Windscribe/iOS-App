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
    func getServers() -> [Server]? {
        return getRealmObjectList(type: Server.self)
    }

    func getSession() -> Session? {
        return getRealmObject(type: Session.self)
    }


    func clearSessionFromRealm() {
        if let object = getSession() {
            deleteRealmObject(object: object)
        }
    }

    // MARK: - Server V2 Architecture
    func getLocations() -> [LocationObject]? {
        return getRealmObjectList(type: LocationObject.self)
    }

    func saveLocations(locations: [LocationObject]) {
        return updateRealmObjects(objects: locations)
    }

    func getServerMachines() -> [ServerMachineObject]? {
        return getRealmObjectList(type: ServerMachineObject.self)
    }

    func getServerMachinesPublisher() -> AnyPublisher<[ServerMachineObject], Never> {
        return getSafeRealmArrayPublisher(type: ServerMachineObject.self)
    }

    func saveServerMachines(serverMachines: [ServerMachineObject]) {
        return updateRealmObjects(objects: serverMachines)
    }

    // MARK: - Before Modelization of Database

    func getMobilePlans() -> [MobilePlan]? {
        return getRealmObjectList(type: MobilePlan.self)
    }

    func saveMobilePlans(mobilePlansList: [MobilePlan]) {
        return updateRealmObjects(objects: mobilePlansList)
    }

    func getCustomConfigs() -> [CustomConfig] {
        return getRealmObjectList(type: CustomConfig.self) ?? []
    }

    func saveCustomConfig(customConfig: CustomConfig) {
        do {
            let realm = try Realm()
            try realm.safeWrite {
                realm.add(customConfig, update: .modified)
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

    func getCustomConfigPublisher() -> AnyPublisher<[CustomConfig], Never> {
        return getSafeRealmArrayPublisher(type: CustomConfig.self)
    }

    func getStaticIPs() -> [StaticIP]? {
        return getRealmObjectList(type: StaticIP.self)
    }

    func saveStaticIPs(staticIps: [StaticIP]) {
        return updateRealmObjects(objects: staticIps)
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

    func getOpenVPNServerCredentials() -> OpenVPNServerCredentials? {
        return getRealmObject(type: OpenVPNServerCredentials.self)
    }

    func getIKEv2ServerCredentials() -> IKEv2ServerCredentials? {
        return getRealmObject(type: IKEv2ServerCredentials.self)
    }

    func clearOpenVPNServerCredentials() {
        if let object = getOpenVPNServerCredentials() {
            deleteRealmObject(object: object)
        }
    }

    func clearIKEv2ServerCredentials() {
        if let object = getIKEv2ServerCredentials() {
            deleteRealmObject(object: object)
        }
    }

    func getPortMap() -> [PortMap]? {
        return getRealmObjectList(type: PortMap.self)
    }

    func getSuggestedPorts() -> [SuggestedPorts]? {
        return getRealmObjectList(type: SuggestedPorts.self)
    }

    func saveSuggestedPorts(suggestedPorts: [SuggestedPorts]) {
        return updateRealmObjects(objects: suggestedPorts)
    }

    func savePortMap(portMap: [PortMap]) {
        return updateRealmObjects(objects: portMap)
    }

    func getNotificationsPublisher() -> AnyPublisher<[Notice], Never> {
        return getSafeRealmArrayPublisher(type: Notice.self)
    }

    func saveNotifications(notifications: [Notice]) {
        do {
            let realm = try Realm()
            try realm.safeWrite {
                // Delete all existing notifications first to remove stale ones
                let existingNotifications = realm.objects(Notice.self)
                realm.delete(existingNotifications)

                // Add all new notifications from API
                for notification in notifications {
                    realm.add(notification, update: .modified)
                }
            }
        } catch {
            logger.logE("LocalDatabaseImpl", "Failed to save notifications: \(error.localizedDescription)")
        }
    }

    func getReadNoticesPublisher() -> AnyPublisher<[ReadNotice], Never> {
        return getSafeRealmArrayPublisher(type: ReadNotice.self)
    }

    func getReadNotices() -> [ReadNotice]? {
        return getRealmObjectList(type: ReadNotice.self)
    }

    func saveReadNotices(readNotices: [ReadNotice]) {
        return updateRealmObjects(objects: readNotices)
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

    func getNetworksPublisher() -> AnyPublisher<[WifiNetwork], Never> {
        return getSafeRealmArrayPublisher(type: WifiNetwork.self)
    }

    func saveNetwork(wifiNetwork: WifiNetwork) {
        return updateRealmObject(object: wifiNetwork)
    }

    func removeNetwork(wifiNetwork: WifiNetwork) {
        if let managedNetwork = getRealmObject(type: WifiNetwork.self, primaryKey: wifiNetwork.SSID) {
            deleteRealmObject(object: managedNetwork)
        }
    }

    func getAllPingData() -> [PingData] {
        return getRealmObjectList(type: PingData.self) ?? []
    }

    func addPingData(pingData: PingData) {
        autoreleasepool {
            let realm = try? Realm()
            try? realm?.write {
                realm?.add(pingData, update: .modified)
            }
        }
    }

    func getRobertFilters() -> RobertFilters? {
        return getRealmObject(type: RobertFilters.self)
    }

    func saveRobertFilters(filters: RobertFilters) {
        return updateRealmObject(object: filters)
    }

    func saveFavourite(favourite: Favourite) {
        return updateRealmObject(object: favourite)
    }

    func getFavouriteListPublisher() -> AnyPublisher<[Favourite], Never> {
        return getSafeRealmArrayPublisher(type: Favourite.self)
    }

    func getFavouriteList() -> [Favourite] {
        return getRealmObjectList(type: Favourite.self) ?? []
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

    func saveUnblockWgParams(params: [UnblockWgParamsObj] ) {
        return updateRealmObjects(objects: params)
    }

    func getUnblockWgParams() -> [UnblockWgParamsObj] {
        return getRealmObjectList(type: UnblockWgParamsObj.self) ?? []
    }

    func toggleRobertRule(id: String) {
        guard let object = getRobertFilters() else { return }
        let o = object.filters.first {
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

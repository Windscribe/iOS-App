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
import RxSwift
import Combine

class LocalDatabaseImpl: LocalDatabase {
    let logger: FileLogger
    let disposeBag = DisposeBag()
    let cleanTrigger = PublishSubject<Void>()
    let cleanSubject = PassthroughSubject<Void, Never>()
    let preferences: Preferences

    init(logger: FileLogger, preferences: Preferences) {
        self.logger = logger
        self.preferences = preferences
    }

    //MARK: After Modelization of Database

    func getServers() -> [Server]? {
        return getRealmObjects(type: Server.self)
    }

    func saveServers(servers: [Server]) {
        return updateRealmObjects(objects: servers)
    }

    //MARK: Before Modelization of Database

    @MainActor
    func saveSession(session: Session) async {
        do {
            let realm = try await Realm()
            try realm.safeWrite {
                realm.add(session, update: .modified)
            }
        } catch {
            logger.logE("LocalDatabaseImpl", "Failed to save session: \(error.localizedDescription)")
        }
    }

    func getSession() -> Observable<Session?> {
        return getSafeRealmObservable(type: Session.self)
    }

    func getSessionSync() -> Session? {
        return getRealmObject(type: Session.self)
    }

    func getMobilePlans() -> [MobilePlan]? {
        return getRealmObjects(type: MobilePlan.self)
    }

    func saveMobilePlans(mobilePlansList: [MobilePlan]) {
        return updateRealmObjects(objects: mobilePlansList)
    }

    func getCustomConfigs() -> [CustomConfig] {
        return getRealmObjects(type: CustomConfig.self) ?? []
    }

    @MainActor
    func saveCustomConfig(customConfig: CustomConfig) async {
        do {
            let realm = try await Realm()
            try realm.safeWrite {
                realm.add(customConfig, update: .modified)
            }
        } catch {
            logger.logE("LocalDatabaseImpl", "Failed to save custom config: \(error.localizedDescription)")
        }
    }

    func getCustomConfig() -> Observable<[CustomConfig]> {
        return getSafeRealmObservable(type: CustomConfig.self)
    }

    func getStaticIPs() -> [StaticIP]? {
        return getRealmObjects(type: StaticIP.self)
    }

    func saveStaticIPs(staticIps: [StaticIP]) {
        return updateRealmObjects(objects: staticIps)
    }

    func deleteStaticIps(ignore: [String]) {
        if let objects = getRealmObjects(type: StaticIP.self) {
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

    func saveOpenVPNServerCredentials(credentials: OpenVPNServerCredentials) -> Disposable {
        return updateRealmObject(object: credentials)
    }

    func getIKEv2ServerCredentials() -> IKEv2ServerCredentials? {
        return getRealmObject(type: IKEv2ServerCredentials.self)
    }

    func saveIKEv2ServerCredentials(credentials: IKEv2ServerCredentials) -> Disposable {
        return updateRealmObject(object: credentials)
    }

    func getPortMap() -> [PortMap]? {
        return getRealmObjects(type: PortMap.self)
    }

    func getSuggestedPorts() -> [SuggestedPorts]? {
        return getRealmObjects(type: SuggestedPorts.self)
    }

    func saveSuggestedPorts(suggestedPorts: [SuggestedPorts]) {
        return updateRealmObjects(objects: suggestedPorts)
    }

    func savePortMap(portMap: [PortMap]) {
        return updateRealmObjects(objects: portMap)
    }

    func getNotifications() -> [Notice]? {
        return getRealmObjects(type: Notice.self)
    }

    func getNotificationsObservable() -> Observable<[Notice]> {
        return getSafeRealmObservable(type: Notice.self)
    }

    @MainActor
    func saveNotifications(notifications: [Notice]) async {
        do {
            let realm = try await Realm()
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

    func getReadNoticesObservable() -> Observable<[ReadNotice]> {
        return getSafeRealmObservable(type: ReadNotice.self)
    }

    func getReadNotices() -> [ReadNotice]? {
        return getRealmObjects(type: ReadNotice.self)
    }

    func saveReadNotices(readNotices: [ReadNotice]) {
        return updateRealmObjects(objects: readNotices)
    }

    func getIp() -> Observable<MyIP?> {
        return getSafeRealmObservable(type: MyIP.self)
    }

    func saveIp(myip: MyIP) -> Disposable {
        return updateRealmObject(object: myip)
    }

    func getNetworks() -> Observable<[WifiNetwork]> {
        return getSafeRealmObservable(type: WifiNetwork.self)
    }

    func getPublishedNetworks() -> AnyPublisher<[WifiNetwork], Never> {
        return getSafeRealmPublisher(type: WifiNetwork.self)
    }

    func getNetworksSync() -> [WifiNetwork]? {
        return getRealmObjects(type: WifiNetwork.self)
    }

    func saveNetwork(wifiNetwork: WifiNetwork) {
        return updateRealmObject(object: wifiNetwork)
    }

    func removeNetwork(wifiNetwork: WifiNetwork) {
        deleteRealmObject(object: wifiNetwork)
    }

    func getAllPingData() -> [PingData] {
        return getRealmObjects(type: PingData.self) ?? []
    }

    func addPingData(pingData: PingData) {
        autoreleasepool {
            let realm = try? Realm()
            try? realm?.write {
                realm?.add(pingData, update: .modified)
            }
        }
    }

    func removeCustomConfig(fileId: String) {
        if let object = getRealmObject(type: CustomConfig.self, primaryKey: fileId) {
            deleteRealmObject(object: object)
        }
    }

    func getRobertFilters() -> RobertFilters? {
        return getRealmObject(type: RobertFilters.self)
    }

    func getUserPreferences() -> UserPreferences? {
        return getRealmObject(type: UserPreferences.self)
    }

    func saveRobertFilters(filters: RobertFilters) -> Disposable {
        return updateRealmObject(object: filters)
    }

    func getLastConnection() -> Observable<VPNConnection?> {
        return getSafeRealmObservable(type: VPNConnection.self)
    }

    func saveLastConnetion(vpnConnection: VPNConnection) -> Disposable {
        return updateRealmObject(object: vpnConnection)
    }

    func saveFavourite(favourite: Favourite) -> Disposable {
        return updateRealmObject(object: favourite)
    }

    func getFavouriteListObservable() -> Observable<[Favourite]> {
        return getSafeRealmObservable(type: Favourite.self)
    }

    func getFavouriteList() -> [Favourite] {
        return getRealmObjects(type: Favourite.self) ?? []
    }

    func removeFavourite(groupId: String) {
        if let object = getRealmObject(type: Favourite.self, primaryKey: groupId) {
            deleteRealmObject(object: object)
        }
    }

    func saveOldSession() {
        let realm = try? Realm()
        if let session = realm?.objects(Session.self).first {
            let oldSession = OldSession(session: session)
            let realm = try? Realm()
            try? realm?.safeWrite {
                realm?.add(oldSession, update: .modified)
            }
        }
    }

    func getOldSession() -> OldSession? {
        return getRealmObject(type: OldSession.self)
    }

    func saveBestNode(node: BestNode) -> Disposable {
        updateRealmObject(object: node)
    }

    func getBestNode() -> [BestNode]? {
        return getRealmObjects(type: BestNode.self)
    }

    func clean() {
        let realm = try? Realm()

        cleanTrigger.onNext(())
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

    func getPorts(protocolType: String) -> [String]? {
        guard let ports = getPortMap() else { return nil }
        let selectedProtocolPorts = ports.filter { $0.heading == protocolType }
        var portsArray = [String]()
        guard let portsList = selectedProtocolPorts.first?.ports else { return nil }
        portsArray.append(contentsOf: portsList)
        return portsArray
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

    func updateNetworkWithPreferredProtocolSwitch(network: WifiNetwork, status: Bool) {
        let updated = network
        do {
            let realm = try Realm()
            try realm.safeWrite {
                updated.preferredProtocolStatus = status
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

    func updateCustomConfigName(customConfigId: String, name: String) {
        guard let customConfig = getRealmObject(type: CustomConfig.self, primaryKey: customConfigId) else { return }

        do {
            let realm = try Realm()
            try realm.safeWrite {
                customConfig.name = name
            }
        } catch {
            fatalError("")
        }
    }

    func updateCustomConfigCredentials(customConfigId: String, username: String, password: String) {
        guard let customConfig = getRealmObject(type: CustomConfig.self, primaryKey: customConfigId) else { return }

        do {
            let realm = try Realm()
            try realm.safeWrite {
                customConfig.username = username
                customConfig.password = password
            }
        } catch {
            fatalError("")
        }
    }

    func updateConnectionMode(value: String) {
        if let userPreferences = getUserPreferences() {
            do {
                let realm = try Realm()
                try realm.safeWrite {
                    userPreferences.connectionMode = value
                }
            } catch {
                fatalError("")
            }
        }
    }
}

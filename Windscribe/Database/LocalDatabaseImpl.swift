//
//  LocalDatabaseImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-25.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import RxRealm
import RxSwift
import Realm
class LocalDatabaseImpl: LocalDatabase {

    private let logger: FileLogger
    private let preferences: Preferences
    private let disposeBag = DisposeBag()
    init(logger: FileLogger, preferences: Preferences) {
        self.logger = logger
        self.preferences = preferences
    }
    func saveSession(session: Session) -> RxSwift.Disposable {
        return updateRealmObject(object: session)
    }

    func getSession() -> Observable<Session> {
        return getRealmObserable(type: Session.self)
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

    func getServers() -> [Server]? {
        return getRealmObjects(type: Server.self)
    }

    func getServersObservable() -> Observable<[Server]> {
        return getRealmObserable(type: Server.self)
    }

    func getCustomConfigs() -> [CustomConfig] {
        return getRealmObjects(type: CustomConfig.self) ?? []
    }

    func saveServers(servers: [Server]) {
        return updateRealmObjects(objects: servers)
    }

    func saveCustomConfig(customConfig: CustomConfig) -> Disposable {
        return updateRealmObject(object: customConfig)
    }

    func getCustomConfig() -> Observable<[CustomConfig]> {
        return getRealmObserable(type: CustomConfig.self)
    }

    func getStaticIPs() -> [StaticIP]? {
        return getRealmObjects(type: StaticIP.self)
    }

    func saveStaticIPs(staticIps: [StaticIP]) {
        return updateRealmObjects(objects: staticIps)
    }

    func deleteStaticIps(ignore: [String]) {
        if let objects = getRealmObjects(type: StaticIP.self) {
            objects.forEach { stat in
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

    func savePortMap(portMap: [PortMap]) {
        return updateRealmObjects(objects: portMap)
    }

    func getNotifications() -> [Notice]? {
        return getRealmObjects(type: Notice.self)
    }

    func getNotificationsObservable() -> Observable<[Notice]> {
        return getRealmObserable(type: Notice.self)
    }

    func saveNotifications(notifications: [Notice]) {
        return updateRealmObjects(objects: notifications)
    }

    func getReadNoticesObservable() -> Observable<[ReadNotice]> {
        return getRealmObserable(type: ReadNotice.self)
    }

    func getReadNotices() -> [ReadNotice]? {
        return getRealmObjects(type: ReadNotice.self)
    }

    func saveReadNotices(readNotices: [ReadNotice]) {
        return updateRealmObjects(objects: readNotices)
    }

    func getIp() -> Observable<MyIP> {
        return getRealmObserable(type: MyIP.self)
    }

    func saveIp(myip: MyIP) -> Disposable {
        logger.logD(self, "Saving My ip to database.")
        return updateRealmObject(object: myip)
    }

    func getNetworks() -> Observable<[WifiNetwork]> {
        return getRealmObserable(type: WifiNetwork.self)
    }

    func getNetworksSync() -> [WifiNetwork]? {
        return getRealmObjects(type: WifiNetwork.self)
    }

    func saveNetwork(wifiNetwork: WifiNetwork) -> Disposable {
        return updateRealmObject(object: wifiNetwork)
    }

    func removeNetwork(wifiNetwork: WifiNetwork) {
        deleteRealmObject(object: wifiNetwork)
    }

    func getAllPingData() -> [PingData] {
        return getRealmObjects(type: PingData.self) ?? []
    }

    func addPingData(pingData: PingData) -> Disposable {
        return updateRealmObject(object: pingData)
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

    func saveLastConnectedNode(node: LastConnectedNode) -> Disposable {
        return updateRealmObject(object: node)
    }

    func getLastConnectedNode() -> LastConnectedNode? {
        return getRealmObjects(type: LastConnectedNode.self)?.sorted { $0.connectedAt < $1.connectedAt }.last
    }

    func getBestLocation() -> Observable<BestLocation> {
        return getRealmObserable(type: BestLocation.self)
    }

    func saveBestLocation(location: BestLocation) -> Disposable {
        return updateRealmObject(object: location)
    }

    func removeBestLocation(cityName: String) {
        if let object = getRealmObject(type: BestLocation.self, primaryKey: cityName) {
            deleteRealmObject(object: object)
        }
    }

    func getLastConnection() -> Observable<VPNConnection> {
        return getRealmObserable(type: VPNConnection.self)

    }
    func saveLastConnetion(vpnConnection: VPNConnection) -> Disposable {
        return updateRealmObject(object: vpnConnection)
    }

    func saveFavNode(favNode: FavNode) -> Disposable {
        return updateRealmObject(object: favNode)
    }

    func getFavNode() -> Observable<[FavNode]> {
        return getRealmObserable(type: FavNode.self)
    }

    func getFavNodeSync() -> [FavNode] {
        return getRealmObjects(type: FavNode.self) ?? []
    }

    func removeFavNode(hostName: String) {
        if let object = getRealmObject(type: FavNode.self, primaryKey: hostName) {
            deleteRealmObject(object: object)
        }
    }

    func saveOldSession() {
        let realm = try? Realm()
        if let session = realm?.objects(Session.self).first {
            let oldSession = OldSession(session: session)
            self.updateRealmObject(object: oldSession).disposed(by: self.disposeBag)
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

    func getGroups() -> [Group]? {
        return getRealmObjects(type: Group.self)
    }

    func clean() {
        let realm = try? Realm()
        try? realm?.write {
            realm?.deleteAll()
        }
    }

    // MARK: Utility

    func getRealmObject<T: Object>(type: T.Type) -> T? {
        return try? Realm().objects(type).first
    }

    func getRealmObject<T: Object>(type: T.Type, primaryKey: String) -> T? {
        return try? Realm().object(ofType: type, forPrimaryKey: primaryKey)
    }

    func getRealmObjects<T: Object>(type: T.Type) -> [T]? {
        return try? Realm().objects(type).toArray()
    }

    func updateRealmObject<T: Object>(object: T) -> Disposable {
        return Observable.from(object: object)
            .subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: { obj in
                let realm = try? Realm()
                try?realm?.safeWrite {
                    realm?.add(obj, update: .modified)
                }
            }, onError: { _ in})
    }

    func updateRealmObjects<T: Object>(objects: [T]) {
        DispatchQueue.main.async {
            let realm = try? Realm()
            try?realm?.safeWrite {
                objects.forEach { obj in
                    realm?.add(obj, update: .modified)
                }
            }
        }
    }

    func getRealmObserable<T: Object>(type: T.Type) -> Observable<T> {
        if let object = getRealmObject(type: type) {
            return Observable.from(object: object).catch { _ in
                return Observable.empty()
            }
        } else {
            return Observable.empty()
        }
    }

    // swiftlint:disable force_try
    private func getRealmObserable<T: Object>(type: T.Type) -> Observable<[T]> {
        let realm = try! Realm()
        let objects = realm.objects(type.self)
        return Observable.changeset(from: objects)
            .filter { _ , changeset in
                guard let changeset = changeset else {
                    return true
                }
               return !changeset.deleted.isEmpty || !changeset.inserted.isEmpty || !changeset.updated.isEmpty
            }.map { results, _ in
                return AnyRealmCollection(results)
            }.catchAndReturn(AnyRealmCollection(try! Realm().objects(T.self)))
            .map { $0.toArray() }
    }
    // swiftlint:enable force_try

    func deleteRealmObject<T: Object>(object: T) {
        try? object.realm?.write {
            object.realm?.delete(object)
        }
    }

    func deleteRealmObject<T: Object>(objects: [T]) {
        let realm = try? Realm()
        try? realm?.safeWrite {
            realm?.delete(objects)
        }
    }

    // MARK: migration
    func migrate() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 50,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: Session.className()) { _,_ in }
                } else if oldSchemaVersion < 2 {
                    var nextID = 0
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["id"] = nextID
                        nextID += 1
                    }
                    migration.enumerateObjects(ofType: Server.className()) { _, newObject in
                        newObject!["id"] = nextID
                        nextID += 1
                    }
                } else if oldSchemaVersion < 3 {
                    var nextID = 0
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject!["id"] = nextID
                        nextID += 1
                    }
                } else if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["appearance"] = TextsAsset.appearances[0]
                    }
                } else if oldSchemaVersion < 5 {
                    migration.enumerateObjects(ofType: ReadNotice.className()) { oldObject, newObject in
                        newObject!["id"] = oldObject!["id"]
                    }
                } else if oldSchemaVersion < 6 {
                    migration.enumerateObjects(ofType: AutomaticMode.className()) { _, newObject in
                        newObject!["SSID"] = WifiManager.shared.getConnectedWifiNetworkSSID() ?? "NO_CONN"
                    }
                } else if oldSchemaVersion < 7 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _,_ in }
                } else if oldSchemaVersion < 8 {
                    migration.enumerateObjects(ofType: Node.className()) { _, newObject in
                        newObject!["forceDisconnect"] = false
                    }
                } else if oldSchemaVersion < 9 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _,_ in }
                } else if oldSchemaVersion < 10 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _,_ in }
                } else if oldSchemaVersion < 11 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _,_ in }
                } else if oldSchemaVersion < 12 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _,_ in }
                } else if oldSchemaVersion < 13 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _,_ in }
                } else if oldSchemaVersion < 14 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _,_ in }
                } else if oldSchemaVersion < 15 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _,_ in }
                } else if oldSchemaVersion < 16 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _,_ in }
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { _,_ in }
                } else if oldSchemaVersion < 17 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _,_ in }
                } else if oldSchemaVersion < 18 {
                    migration.enumerateObjects(ofType: StaticIP.className()) { _,_ in }
                } else if oldSchemaVersion < 19 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _,_ in }
                } else if oldSchemaVersion < 20 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, newObject in
                        newObject!["preferredProtocolStatus"] = false
                        newObject!["preferredProtocol"] = wireGuard
                        newObject!["preferredPort"] = "443"
                    }
                } else if oldSchemaVersion < 21 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _,_ in }
                } else if oldSchemaVersion < 22 {
                    migration.enumerateObjects(ofType: Notice.className()) { _,_ in }
                } else if oldSchemaVersion < 23 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _,_ in }
                } else if oldSchemaVersion < 24 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["autoSecureNewNetworks"] = true
                    }
                } else if oldSchemaVersion < 27 {
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { _, newObject in
                        newObject!["connectedAt"] = Date()
                    }
                } else if oldSchemaVersion < 28 {
                    migration.enumerateObjects(ofType: Group.className()) { _,_ in }
                } else if oldSchemaVersion < 29 {
                    migration.enumerateObjects(ofType: StaticIP.className()) { _,_ in }
                } else if oldSchemaVersion < 30 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _,_ in }
                } else if oldSchemaVersion < 31 {
                    migration.enumerateObjects(ofType: VPNConnection.className()) { _,_ in }
                } else if oldSchemaVersion < 32 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, newObject in
                        newObject!["protocolType"] = wireGuard
                        newObject!["port"] = "443"
                    }
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["hapticFeedback"] = true
                    }
                } else if oldSchemaVersion < 33 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["hapticFeedback"] = true
                    }
                } else if oldSchemaVersion < 34 {
                    migration.enumerateObjects(ofType: Node.className()) { _,_ in }
                } else if oldSchemaVersion < 35 {
                    migration.enumerateObjects(ofType: Group.className()) { _,_ in }
                } else if oldSchemaVersion < 36 {
                    migration.enumerateObjects(ofType: BestNode.className()) { _,_ in }
                } else if oldSchemaVersion < 37 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _,_ in }
                } else if oldSchemaVersion < 39 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["protocolType"] = wireGuard
                        newObject!["port"] = "443"
                    }
                } else if oldSchemaVersion < 42 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["ovpnX509"] = ""
                    }
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject!["ovpnX509"] = ""
                    }
                } else if oldSchemaVersion < 43 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["health"] = 0
                        newObject!["linkSpeed"] = "1000"
                    }
                    migration.enumerateObjects(ofType: FavNode.className()) { _, newObject in
                        newObject!["health"] = 0
                        newObject!["linkSpeed"] = "1000"
                    }
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["showServerHealth"] = false
                    }
                    migration.enumerateObjects(ofType: Notice.className()) { _, newObject in
                        newObject!["permFree"] = false
                        newObject!["permPro"] = false
                        newObject!["action"] = nil
                    }
                    migration.enumerateObjects(ofType: MobilePlan.className()) { _, newObject in
                        newObject!["discount"] = 0
                        newObject!["duration"] = 0
                    }
                } else if oldSchemaVersion < 44 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["killSwitch"] = false
                        newObject!["allowLan"] = false
                    }
                } else if oldSchemaVersion < 45 {
                    migration.enumerateObjects(ofType: AutomaticMode.className()) { _, newObject in
                        newObject!["wgFailed"] = 0
                        newObject!["wsTunnelFailed"] = 0
                        newObject!["stealthFailed"] = 0
                    }
                } else if oldSchemaVersion < 46 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["pingHost"] = ""
                    }
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject!["pingHost"] = ""
                    }
                } else if oldSchemaVersion < 47 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { oldObject, _ in
                        if let latencyType = oldObject?["latencyType"] as? String {
                            self.preferences.saveLatencyType(latencyType: latencyType)
                        }
                        if let connectionMode = oldObject?["connectionMode"] as? String {
                            self.preferences.saveConnectionMode(mode: connectionMode)
                        }
                        if let language = oldObject?["language"] as? String {
                            self.preferences.saveLanguage(language: language)
                        }
                        if let orderLocationsBy = oldObject?["orderLocationsBy"] as? String {
                            self.preferences.saveOrderLocationsBy(order: orderLocationsBy)
                        }
                        if let appearance = oldObject?["appearance"] as? String {
                            self.preferences.saveAppearance(appearance: appearance)
                        }
                        if let firewall = oldObject?["firewall"] as? Bool {
                            self.preferences.saveFirewallMode(firewall: firewall)
                        }
                        if let killSwitch = oldObject?["killSwitch"] as? Bool {
                            self.preferences.saveKillSwitch(killSwitch: killSwitch)
                        }
                        if let allowLan = oldObject?["allowLan"] as? Bool {
                            self.preferences.saveAllowLane(mode: allowLan)
                        }
                        if let autoSecureNewNetworks = oldObject?["autoSecureNewNetworks"] as? Bool {
                            self.preferences.saveAutoSecureNewNetworks(autoSecure: autoSecureNewNetworks)
                        }
                        if let hapticFeedback = oldObject?["hapticFeedback"] as? Bool {
                            self.preferences.saveHapticFeedback(haptic: hapticFeedback)
                        }
                        if let showServerHealth = oldObject?["showServerHealth"] as? Bool {
                            self.preferences.saveShowServerHealth(show: showServerHealth)
                        }
                        if let protocolType = oldObject?["protocolType"] as? String {
                            self.preferences.saveSelectedProtocol(selectedProtocol: protocolType)
                        }
                        if let port = oldObject?["port"] as? String {
                            self.preferences.saveSelectedPort(port: port)
                        }
                    }
                    migration.enumerateObjects(ofType: PortMap.className()) { _,_ in }
                    migration.enumerateObjects(ofType: PingData.className()) { _,_ in }
                    migration.enumerateObjects(ofType: MyIP.className()) { _,_ in }
                    migration.enumerateObjects(ofType: OpenVPNServerCredentials.className()) { _, newObject in
                        newObject!["id"] = "OpenVPNServerCredentials"
                    }
                    migration.enumerateObjects(ofType: IKEv2ServerCredentials.className()) { _, newObject in
                        newObject!["id"] = "IKEv2ServerCredentials"
                    }
                } else if oldSchemaVersion < 48 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, newObject in
                        newObject!["pingHost"] = ""
                    }
                } else if oldSchemaVersion < 49 {
                    migration.enumerateObjects(ofType: MobilePlan.className()) { _,_ in }
                } else if oldSchemaVersion < 50 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, newObject in
                        newObject!["isPremiumOnly"] = false
                    }
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { _, newObject in
                        newObject!["isPremiumOnly"] = false
                    }
                }
            }, deleteRealmIfMigrationNeeded: false)
    }

    func getPorts(protocolType: String) -> [String]? {
        guard let ports = getPortMap() else { return nil }
        let selectedProtocolPorts = ports.filter({$0.heading == protocolType})
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
                properties.forEach { (property: String, value: Any) in
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
                            return
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

    func getServerAndGroup(bestNodeHostname: String) -> (ServerModel, GroupModel)? {
        guard let servers = getServers() else { return nil }
        var serverResult: ServerModel?
        var groupResult: GroupModel?
        for server in servers.map({$0.getServerModel()}) {
            for group in server?.groups ?? [] where group.bestNodeHostname == bestNodeHostname {
                serverResult = server
                groupResult = group
            }
        }
        guard let serverResultSafe = serverResult, let groupResultSafe = groupResult else { return nil }
        return (serverResultSafe, groupResultSafe)
    }
}

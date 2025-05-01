//
//  MainViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 18/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import StoreKit

protocol MainViewModelType {
    var serverList: BehaviorSubject<[ServerModel]> { get }
    var lastConnection: BehaviorSubject<VPNConnection?> { get }
    var portMap: BehaviorSubject<[PortMap]?> { get }
    var favNode: BehaviorSubject<[FavNode]?> { get }
    var staticIPs: BehaviorSubject<[StaticIP]?> { get }
    var customConfigs: BehaviorSubject<[CustomConfig]?> { get }
    var oldSession: OldSession? { get }
    var locationOrderBy: BehaviorSubject<String> { get }
    var latencies: BehaviorSubject<[PingData]> { get }
    var notices: BehaviorSubject<[Notice]> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    var selectedProtocol: BehaviorSubject<String> { get }
    var selectedPort: BehaviorSubject<String> { get }
    var connectionMode: BehaviorSubject<String> { get }
    var appNetwork: BehaviorSubject<AppNetwork> { get }
    var wifiNetwork: BehaviorSubject<WifiNetwork?> { get }
    var session: BehaviorSubject<Session?> { get }
    var favouriteGroups: BehaviorSubject<[GroupModel]> { get }

    var showNetworkSecurityTrigger: PublishSubject<Void> { get }
    var showNotificationsTrigger: PublishSubject<Void> { get }
    var becameActiveTrigger: PublishSubject<Void> { get }
    var updateSSIDTrigger: PublishSubject<Void> { get }

    var didShowProPlanExpiredPopup: Bool { get set }
    var didShowOutOfDataPopup: Bool { get set }
    var promoPayload: BehaviorSubject<PushNotificationPayload?> { get }
    func loadServerList()
    func sortServerListUsingUserPreferences(isForStreaming: Bool, servers: [ServerModel], completion: @escaping (_ result: [ServerSection]) -> Void)
    func loadPortMap()
    func loadStaticIPLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func loadCustomConfigLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func checkForUnreadNotifications(completion: @escaping (_ showNotifications: Bool, _ readNoticeDifferentCount: Int) -> Void)
    func saveLastNotificationTimestamp()
    func getLastNotificationTimestamp() -> Double?
    func sortFavouriteNodesUsingUserPreferences(favNodes: [FavNodeModel]) -> [FavNodeModel]
    func getPortList(protocolName: String) -> [String]?
    func getStaticIp() -> [StaticIP]
    func getLatency(ip: String?) -> Int
    func isPrivacyPopupAccepted() -> Bool
    func updatePreferredProtocolSwitch(network: WifiNetwork, preferredProtocolStatus: Bool)
    func updateTrustNetworkSwitch(network: WifiNetwork, status: Bool)
    func getCustomConfig(customConfigID: String?) -> CustomConfigModel?

    func updatePreferred(port: String, and proto: String, for network: WifiNetwork)
    func updateSSID()
    func getServerModel(from groupId: Int) -> ServerModel?
}

class MainViewModel: MainViewModelType {
    let themeManager: ThemeManager
    let localDatabase: LocalDatabase
    let vpnManager: VPNManager
    let logger: FileLogger
    let serverRepository: ServerRepository
    let portMapRepo: PortMapRepository
    let staticIpRepository: StaticIpRepository
    let preferences: Preferences
    let latencyRepo: LatencyRepository
    let connectivity: Connectivity
    let pushNotificationsManager: PushNotificationManagerV2!
    let notificationsRepo: NotificationRepository!
    let credentialsRepository: CredentialsRepository
    let livecycleManager: LivecycleManagerType
    let locationsManager: LocationsManagerType

    let serverList = BehaviorSubject<[ServerModel]>(value: [])
    var lastConnection = BehaviorSubject<VPNConnection?>(value: nil)
    var portMap = BehaviorSubject<[PortMap]?>(value: nil)
    var favNode = BehaviorSubject<[FavNode]?>(value: nil)
    var staticIPs = BehaviorSubject<[StaticIP]?>(value: nil)
    var customConfigs = BehaviorSubject<[CustomConfig]?>(value: nil)
    var locationOrderBy = BehaviorSubject<String>(value: DefaultValues.orderLocationsBy)
    let latencies = BehaviorSubject<[PingData]>(value: [])
    var notices = BehaviorSubject<[Notice]>(value: [])
    var selectedProtocol = BehaviorSubject<String>(value: DefaultValues.protocol)
    var selectedPort = BehaviorSubject<String>(value: DefaultValues.port)
    var connectionMode = BehaviorSubject<String>(value: DefaultValues.connectionMode)
    var appNetwork = BehaviorSubject<AppNetwork>(value: AppNetwork(.disconnected, networkType: .none, name: nil, isVPN: false))
    var wifiNetwork = BehaviorSubject<WifiNetwork?>(value: nil)
    var session = BehaviorSubject<Session?>(value: nil)
    var favouriteGroups = BehaviorSubject<[GroupModel]>(value: [])
    let promoPayload: BehaviorSubject<PushNotificationPayload?> = BehaviorSubject(value: nil)

    let showNetworkSecurityTrigger: PublishSubject<Void>
    let showNotificationsTrigger: PublishSubject<Void>
    let becameActiveTrigger: PublishSubject<Void>
    let updateSSIDTrigger = PublishSubject<Void>()

    var oldSession: OldSession? { localDatabase.getOldSession() }

    var didShowProPlanExpiredPopup = false
    var didShowOutOfDataPopup = false
    let isDarkMode: BehaviorSubject<Bool>

    let disposeBag = DisposeBag()
    init(localDatabase: LocalDatabase, vpnManager: VPNManager, logger: FileLogger, serverRepository: ServerRepository, portMapRepo: PortMapRepository, staticIpRepository: StaticIpRepository, preferences: Preferences, latencyRepo: LatencyRepository, themeManager: ThemeManager, pushNotificationsManager: PushNotificationManagerV2, notificationsRepo: NotificationRepository, credentialsRepository: CredentialsRepository, connectivity: Connectivity, livecycleManager: LivecycleManagerType, locationsManager: LocationsManagerType) {
        self.localDatabase = localDatabase
        self.vpnManager = vpnManager
        self.logger = logger
        self.serverRepository = serverRepository
        self.portMapRepo = portMapRepo
        self.staticIpRepository = staticIpRepository
        self.preferences = preferences
        self.latencyRepo = latencyRepo
        self.themeManager = themeManager
        self.pushNotificationsManager = pushNotificationsManager
        self.notificationsRepo = notificationsRepo
        self.credentialsRepository = credentialsRepository
        self.connectivity = connectivity
        self.livecycleManager = livecycleManager
        self.locationsManager = locationsManager

        showNetworkSecurityTrigger = livecycleManager.showNetworkSecurityTrigger
        showNotificationsTrigger = livecycleManager.showNotificationsTrigger
        becameActiveTrigger = livecycleManager.becameActiveTrigger

        isDarkMode = themeManager.darkTheme
        loadNotifications()
        loadServerList()
        loadFavNode()
        loadTvFavourites()
        loadStaticIps()
        loadCustomConfigs()
        observeNetworkStatus()
        observeWifiNetwork()
        observeSession()
        preferences.getOrderLocationsBy().subscribe(onNext: { [self] order in
            self.locationOrderBy.onNext(order ?? DefaultValues.orderLocationsBy)
        }, onError: { _ in }).disposed(by: disposeBag)
        loadLastConnection()
        loadLatencies()
        getNotices()
        preferences.getSelectedProtocol().subscribe(onNext: { [self] data in
            self.selectedProtocol.onNext(data ?? DefaultValues.protocol)
        }, onError: { _ in }).disposed(by: disposeBag)
        preferences.getSelectedPort().subscribe(onNext: { [self] data in
            self.selectedPort.onNext(data ?? DefaultValues.port)
        }, onError: { _ in }).disposed(by: disposeBag)
        preferences.getConnectionMode().subscribe(onNext: { [self] data in
            self.connectionMode.onNext(data ?? DefaultValues.connectionMode)
        }, onError: { _ in }).disposed(by: disposeBag)
        serverRepository.updatedServerModelsSubject.subscribe(onNext: { [self] data in
            self.serverList.onNext(data)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    private func observeWifiNetwork() {
        Observable.combineLatest(localDatabase.getNetworks(), connectivity.network).observe(on: MainScheduler.asyncInstance).subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: { [self] (networks, appNetwork) in
            guard let matchingNetwork = networks.first(where: {
                $0.isInvalidated == false && $0.SSID == appNetwork.name
            }) else { return }
            self.wifiNetwork.onNext(matchingNetwork)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    private func observeSession() {
        localDatabase.getSession().subscribe(onNext: { session in
            self.session.onNext(session)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func observeNetworkStatus() {
        connectivity.network.subscribe(onNext: { network in
            self.appNetwork.onNext(network)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func sortFavouriteNodesUsingUserPreferences(favNodes: [FavNodeModel]) -> [FavNodeModel] {
        var favNodesOrdered = [FavNodeModel]()
        switch try? locationOrderBy.value() {
        case Fields.Values.geography:
            favNodesOrdered = favNodes
        case Fields.Values.alphabet:
            favNodesOrdered = favNodes.sorted { favNode1, favNode2 -> Bool in
                guard let countryCode1 = favNode1.cityName, let countryCode2 = favNode2.cityName else { return false }
                return countryCode1 < countryCode2
            }
        case Fields.Values.latency:
            favNodesOrdered = favNodes.sorted { favNode1, favNode2 -> Bool in
                let firstLatency = getLatency(ip: favNode1.pingIp)
                let secondLatency = getLatency(ip: favNode2.pingIp)
                return firstLatency < secondLatency
            }
        default:
            return favNodes
        }
        return favNodesOrdered
    }

    func getLatency(ip: String? = nil) -> Int {
        return latencyRepo.getPingData(ip: ip ?? "")?.latency ?? -1
    }

    func sortServerListUsingUserPreferences(isForStreaming: Bool, servers: [ServerModel], completion: @escaping (_ result: [ServerSection]) -> Void) {
        DispatchQueue.main.async {
            var serverSections = [ServerSection]()
            var serverSectionsOrdered = [ServerSection]()
            if servers.count == 0 {
                completion(serverSectionsOrdered)
                return
            }
            serverSections = servers.filter { $0.isForStreaming() == isForStreaming }.map { ServerSection(server: $0, collapsed: true) }
            let orderBy = (try? self.locationOrderBy.value()) ?? DefaultValues.orderLocationsBy
            switch orderBy {
            case Fields.Values.geography:
                serverSectionsOrdered = serverSections
            case Fields.Values.alphabet:
                serverSectionsOrdered = serverSections.sorted { serverSection1, serverSection2 -> Bool in
                    guard let countryCode1 = serverSection1.server?.name, let countryCode2 = serverSection2.server?.name else { return false }
                    return countryCode1 < countryCode2
                }
            case Fields.Values.latency:
                let serversMappedWithPing = serverSections.map {
                    guard let hostnames = $0.server?.groups.filter({$0.pingIp != ""}).map({$0.pingIp}) else { return ($0, -1)}
                    let nodeList = hostnames.compactMap({
                        let latency = self.latencyRepo.getPingData(ip: $0)?.latency
                        return latency == -1 ? nil : latency
                    })
                    guard nodeList.count != 0 else { return ($0, -1) }

                    let latency = nodeList.reduce(0, { (result, value) -> Int in
                        return result + value
                    }) / (nodeList.count)
                    guard latency != 0 else { return ($0, -1) }
                    return ($0, latency)
                }
                let serverMappedSorted = serversMappedWithPing.sorted { (serverSection1, serverSection2) -> Bool in
                    guard serverSection1.1 > 0 else { return false }
                    guard serverSection2.1 > 0 else { return true }
                    return serverSection1.1 < serverSection2.1
                }
                serverSectionsOrdered = serverMappedSorted.map { $0.0 }
            default:
                serverSectionsOrdered = serverSections
            }
            serverSectionsOrdered = self.sortServerNodes(serverList: serverSectionsOrdered, orderBy: orderBy)
            completion(serverSectionsOrdered)
        }
    }

    private func sortServerNodes(serverList: [ServerSection], orderBy: String) -> [ServerSection] {
        guard orderBy != Fields.Values.geography else { return serverList }
        return serverList.map {
            guard let serverModel = $0.server else { return $0 }
            var sortedGroups = [GroupModel]()
            switch orderBy {
            case Fields.Values.latency:
                sortedGroups = serverModel.groups.sorted {
                    guard let ping0 = self.latencyRepo.getPingData(ip: $0.pingIp)?.latency, ping0 != -1 else { return false }
                    guard let ping1 = self.latencyRepo.getPingData(ip: $1.pingIp)?.latency, ping1 != -1 else { return true }
                    return ping0 < ping1
                }
            default:
                sortedGroups = serverModel.groups.sorted {
                    if $0.city == $1.city {
                        return $0.nick < $1.nick
                    }
                    return $0.city < $1.city
                }
            }
            let sortedServerModel = ServerModel(id: serverModel.id, name: serverModel.name, countryCode: serverModel.countryCode, status: serverModel.status, premiumOnly: serverModel.premiumOnly, dnsHostname: serverModel.dnsHostname, groups: sortedGroups, locType: serverModel.locType, p2p: serverModel.p2p)
            return ServerSection(server: sortedServerModel, collapsed: $0.collapsed)
        }
    }

    func loadLastConnection() {
        localDatabase.getLastConnection().subscribe(onNext: { [self] data in
            lastConnection.onNext(data)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func loadPortMap() {
        portMapRepo.getUpdatedPortMap().subscribe(onSuccess: { _ in
            DispatchQueue.main.async {
                self.portMap.onNext(self.localDatabase.getPortMap())
            }
        }).disposed(by: disposeBag)
    }

    private func getFavouriteGroup(id: String, servers: [ServerModel]) -> GroupModel? {
        var groups: [GroupModel] = []
        for server in servers {
            for group in (server.groups) {
                groups.append(group)
            }
        }
        return groups.first { $0.id == Int(id) }
    }

    private func loadTvFavourites() {
        Observable.combineLatest(preferences.observeFavouriteIds(), serverList).map { ids, servers in
            ids.compactMap { id in self.getFavouriteGroup(id: id, servers: servers) }
        }.subscribe(onNext: { groups in
            self.favouriteGroups.onNext(groups)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func loadFavNode() {
        localDatabase.getFavNode()
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [self] data in
                favNode.onNext(data)
            }, onError: { _ in }).disposed(by: disposeBag)
    }

    func loadStaticIps() {
        staticIpRepository.getStaticServers()
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [self] data in
                staticIPs.onNext(data)
            }).disposed(by: disposeBag)
    }

    func loadCustomConfigs() {
        localDatabase.getCustomConfig().filter {$0.filter({$0.isInvalidated}).count == 0}
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [self] data in
                customConfigs.onNext(data)
                updateCustomConfigLatency()
            }).disposed(by: disposeBag)
    }

    func updateCustomConfigLatency() {
        self.latencyRepo.loadCustomConfigLatency().subscribe(onCompleted: {}).disposed(by: self.disposeBag)
    }

    func loadStaticIPLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void) {
        latencyRepo.loadStaticIpLatency().subscribe(onSuccess: { _ in
            completion(true, nil)
        }, onFailure: { error in
            completion(nil, error.localizedDescription)
        }).disposed(by: disposeBag)
    }

    func loadCustomConfigLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void) {
        latencyRepo.loadCustomConfigLatency().subscribe(onCompleted: {
            completion(true, nil)
        }, onError: { error in
            completion(nil, error.localizedDescription)
        }).disposed(by: disposeBag)
    }

    func loadLatencies() {
        latencyRepo.latency.bind(onNext: { [self] data in
            latencies.onNext(data)
        }).disposed(by: disposeBag)
    }

    func getNotices() {
        Observable.combineLatest(localDatabase.getReadNoticesObservable(), localDatabase.getNotificationsObservable()).bind(onNext: { _, notifications in
            self.notices.onNext(notifications)
        }).disposed(by: disposeBag)
    }

    func checkForUnreadNotifications(completion: @escaping (_ showNotifications: Bool, _ readNoticeDifferentCount: Int) -> Void) {
        logger.logD(MainViewController.self, "Checking for unread notifications.")
        DispatchQueue.main.async {
            guard let readNotices = self.localDatabase.getReadNotices(), let notices = self.retrieveNotifications(), let notice = notices.first, let noticeId = notice.id, let noticePopup = notice.popup else { return }
            let readNoticeIds = Set(readNotices.filter { $0.isInvalidated == false }.map {  $0.id })
            let noticeIds = Set(notices.compactMap { $0.id })

            if noticePopup && !readNoticeIds.contains(noticeId) {
                self.logger.logD(MainViewController.self, "New notification to read with popup.")
                completion(true, 0)
            }
            let readNoticeDifferentCount = noticeIds.reduce(0) {
                $0 + (!readNoticeIds.contains($1) ? 1 : 0)
            }
            if readNoticeDifferentCount != 0 {
                self.pushNotificationsManager.setNotificationCount(count: readNoticeDifferentCount)
            } else {
                self.pushNotificationsManager.setNotificationCount(count: 0)
            }
            completion(false, readNoticeDifferentCount)
        }
    }

    func retrieveNotifications() -> [NoticeModel]? {
        guard let notices = try? notices.value() else { return nil }
        if notices.filter({$0.isInvalidated}).count > 0 {
            return nil
        }
        let noticeModels = Array(notices.compactMap { $0.getModel() }.reversed().sorted(by: { $0.id! > $1.id! }).prefix(5))
        return noticeModels
    }

    func saveLastNotificationTimestamp() {
        preferences.saveLastNotificationTimestamp(timeStamp: Date().timeIntervalSince1970)
    }

    func getLastNotificationTimestamp() -> Double? {
        preferences.getLastNotificationTimestamp()
    }

    func loadNotifications() {
        pushNotificationsManager.notification.compactMap { $0 }
            .subscribe(onNext: { self.promoPayload.onNext($0) })
            .disposed(by: disposeBag)
        notices = notificationsRepo.notices
    }

    func getPortList(protocolName: String) -> [String]? {
        let portMap = (try? portMap.value()) ?? []
        if let ports = portMap.first(where: { $0.heading == protocolName })?.ports {
            return Array(ports)
        }
        return nil
    }

    func updatePreferred(port: String, and proto: String, for network: WifiNetwork) {
        localDatabase.updateWifiNetwork(network: network,
                                        properties: [
                                            Fields.WifiNetwork.preferredProtocol: proto,
                                            Fields.WifiNetwork.preferredPort: port
                                        ])
    }

    func updatePreferredProtocolSwitch(network: WifiNetwork, preferredProtocolStatus: Bool) {
        localDatabase.updateNetworkWithPreferredProtocolSwitch(network: network, status: preferredProtocolStatus)
    }

    func updateTrustNetworkSwitch(network: WifiNetwork, status: Bool) {
        localDatabase.updateWifiNetwork(network: network,
                                        properties: [
                                            Fields.WifiNetwork.trustStatus: !status,
                                            Fields.WifiNetwork.preferredProtocolStatus: false
                                        ])
    }

    func loadServerList() {
        serverRepository.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
    }

    func getStaticIp() -> [StaticIP] {
        return localDatabase.getStaticIPs() ?? []
    }

    func isPrivacyPopupAccepted() -> Bool {
        return preferences.getPrivacyPopupAccepted() ?? false
    }

    func getCustomConfig(customConfigID: String?) -> CustomConfigModel? {
        guard let id = customConfigID else { return nil }
        return localDatabase.getCustomConfigs().first { $0.id == id }?.getModel()
    }

    func updateSSID() {
        updateSSIDTrigger.onNext(())
    }

    func getServerModel(from groupId: Int) -> ServerModel? {
        try? locationsManager.getLocation(from: String(groupId)).0
    }
}

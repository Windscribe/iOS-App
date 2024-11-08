//
//  MainViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 18/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol MainViewModelType {
    var serverList: BehaviorSubject<[Server]> { get }
    var bestLocation: BehaviorSubject<BestLocation?> { get }
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
    var favouriteGroups: BehaviorSubject<[Group]> { get }

    var showNetworkSecurityTrigger: PublishSubject<Void> { get }
    var showNotificationsTrigger: PublishSubject<Void> { get }
    var becameActiveTrigger: PublishSubject<Void> { get }

    var isBlurStaticIpAddress: Bool { get }
    var isBlurNetworkName: Bool { get }
    var didShowProPlanExpiredPopup: Bool { get set }
    var didShowOutOfDataPopup: Bool { get set }
    var promoPayload: BehaviorSubject<PushNotificationPayload?> { get }
    func loadServerList()
    func sortServerListUsingUserPreferences(isForStreaming: Bool, servers: [Server], completion: @escaping (_ result: [ServerSection]) -> Void)
    func loadPortMap()
    func loadStaticIPLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func loadCustomConfigLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func checkForUnreadNotifications(completion: @escaping (_ showNotifications: Bool, _ readNoticeDifferentCount: Int) -> Void)
    func saveLastNotificationTimestamp()
    func getLastNotificationTimestamp() -> Double?
    func getConnectionCount() -> Int?
    func sortFavouriteNodesUsingUserPreferences(favNodes: [FavNodeModel]) -> [FavNodeModel]
    func getPortList(protocolName: String) -> [String]?
    func getStaticIp() -> [StaticIP]
    func getLatency(ip: String?) -> Int
    func daysSinceLogin() -> Int
    func showRateDialog() -> Bool
    func isPrivacyPopupAccepted() -> Bool
    func updatePreferredProtocolSwitch(network: WifiNetwork, preferredProtocolStatus: Bool)
    func updateTrustNetworkSwitch(network: WifiNetwork, status: Bool)
    func getLastConnectedNode() -> LastConnectedNode?
    func isAntiCensorshipEnabled() -> Bool
    func markBlurStaticIpAddress(isBlured: Bool)
    func markBlurNetworkName(isBlured: Bool)
    func refreshProtocolInfo()
    func getCustomConfig(customConfigID: String?) -> CustomConfigModel?

    func reconnect()
    func updatePreferred(port: String, and proto: String, for network: WifiNetwork)
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

    let serverList = BehaviorSubject<[Server]>(value: [])
    let bestLocation = BehaviorSubject<BestLocation?>(value: nil)
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
    var favouriteGroups = BehaviorSubject<[Group]>(value: [])
    let promoPayload: BehaviorSubject<PushNotificationPayload?> = BehaviorSubject(value: nil)

    let showNetworkSecurityTrigger: PublishSubject<Void>
    let showNotificationsTrigger: PublishSubject<Void>
    let becameActiveTrigger: PublishSubject<Void>

    var oldSession: OldSession? { localDatabase.getOldSession() }

    var didShowProPlanExpiredPopup = false
    var didShowOutOfDataPopup = false
    let isDarkMode: BehaviorSubject<Bool>
    let refreshProtocolTrigger = PublishSubject<Void>()

    let disposeBag = DisposeBag()
    init(localDatabase: LocalDatabase, vpnManager: VPNManager, logger: FileLogger, serverRepository: ServerRepository, portMapRepo: PortMapRepository, staticIpRepository: StaticIpRepository, preferences: Preferences, latencyRepo: LatencyRepository, themeManager: ThemeManager, pushNotificationsManager: PushNotificationManagerV2, notificationsRepo: NotificationRepository, credentialsRepository: CredentialsRepository, connectivity: Connectivity, livecycleManager: LivecycleManagerType) {
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

        showNetworkSecurityTrigger = livecycleManager.showNetworkSecurityTrigger
        showNotificationsTrigger = livecycleManager.showNotificationsTrigger
        becameActiveTrigger = livecycleManager.becameActiveTrigger

        isDarkMode = themeManager.darkTheme
        getBestLocation()
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
        localDatabase.getServersObservable().subscribe(onNext: { [self] data in
            self.serverList.onNext(data)
        }, onError: { _ in }).disposed(by: disposeBag)
        preferences.getLanguageManagerSelectedLanguage().subscribe(onNext: { [self] _ in
            self.bestLocation.onNext(try? bestLocation.value())
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    private func observeWifiNetwork() {
        Observable.combineLatest(localDatabase.getNetworks(), connectivity.network, refreshProtocolTrigger.asObservable()).subscribe(onNext: { [self] networks, appNetwork, _ in
            guard let matchingNetwork = networks.first(where: {
                $0.SSID == appNetwork.name
            }) else { return }
            self.wifiNetwork.onNext(matchingNetwork)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    private func observeSession() {
        localDatabase.getSession().subscribe(onNext: { session in
            self.session.onNext(session)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func getLastConnectedNode() -> LastConnectedNode? {
        return localDatabase.getLastConnectedNode()
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

    func sortServerListUsingUserPreferences(isForStreaming: Bool, servers: [Server], completion: @escaping (_ result: [ServerSection]) -> Void) {
        DispatchQueue.main.async {
            var serverSections: [ServerSection] = []
            var serverSectionsOrdered = [ServerSection]()
            let serverModels = servers.compactMap { $0.getServerModel() }
            serverSections = serverModels.filter { $0.isForStreaming() == isForStreaming }.map { ServerSection(server: $0, collapsed: true) }
            switch (try? self.locationOrderBy.value()) ?? DefaultValues.orderLocationsBy {
            case Fields.Values.geography:
                serverSectionsOrdered = serverSections
            case Fields.Values.alphabet:
                serverSectionsOrdered = serverSections.sorted { serverSection1, serverSection2 -> Bool in
                    guard let countryCode1 = serverSection1.server?.name, let countryCode2 = serverSection2.server?.name else { return false }
                    return countryCode1 < countryCode2
                }
            case Fields.Values.latency:
                serverSectionsOrdered = serverSections.sorted { serverSection1, serverSection2 -> Bool in
                    guard let hostnamesFirst = serverSection1.server?.groups?.filter({ $0.pingIp != "" }).map({ $0.pingIp }), let hostnamesSecond = serverSection2.server?.groups?.filter({ $0.pingIp != "" }).map({ $0.pingIp }) else { return false }
                    let firstNodeList = hostnamesFirst.map { self.latencyRepo.getPingData(ip: $0 ?? "")?.latency }.filter { $0 != 0 }
                    let secondNodeList = hostnamesSecond.map { self.latencyRepo.getPingData(ip: $0 ?? "")?.latency }.filter { $0 != 0 }
                    let firstLatency = firstNodeList.reduce(0) { result, value -> Int in
                        return result + (value ?? -1)
                    }
                    let secondLatency = secondNodeList.reduce(0) { result, value -> Int in
                        return result + (value ?? -1)
                    }
                    if firstNodeList.count == 0 ||
                        secondNodeList.count == 0 ||
                        firstLatency == 0 ||
                        secondLatency == 0
                    {
                        return false
                    }
                    return (firstLatency / (firstNodeList.count)) < (secondLatency / (secondNodeList.count))
                }
            default:
                serverSectionsOrdered = serverSections
            }
            completion(serverSectionsOrdered)
        }
    }

    func getBestLocation() {
        latencyRepo.bestLocation.subscribe(onNext: { [self] data in
            bestLocation.onNext(data)
        }, onError: { _ in
        }).disposed(by: disposeBag)
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

    private func getFavouriteGroup(id: String, servers: [Server]) -> Group? {
        var groups: [Group] = []
        for server in servers {
            for group in server.groups {
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
        localDatabase.getFavNode().subscribe(onNext: { [self] data in
            favNode.onNext(data)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func loadStaticIps() {
        staticIpRepository.getStaticServers().subscribe(on: MainScheduler.instance).subscribe(onSuccess: { [self] data in
            staticIPs.onNext(data)
        }).disposed(by: disposeBag)
    }

    func loadCustomConfigs() {
        localDatabase.getCustomConfig().flatMap { value in
            Single<[CustomConfig]>.create { single in
                self.latencyRepo.loadCustomConfigLatency().subscribe(onCompleted: {
                    single(.success(value))
                }, onError: { _ in
                    single(.success(value))
                }).disposed(by: self.disposeBag)
                return Disposables.create {}
            }
        }.subscribe(on: MainScheduler.instance).subscribe(onNext: { [self] data in
            customConfigs.onNext(data)
        }).disposed(by: disposeBag)
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
            let readNoticeIds = Set(readNotices.map { $0.id })
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
            self.logger.logD(self, "Read Notices differences count is \(readNoticeDifferentCount)")
            completion(false, readNoticeDifferentCount)
        }
    }

    func retrieveNotifications() -> [NoticeModel]? {
        guard let notices = try? notices.value() else { return nil }
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

    func getConnectionCount() -> Int? {
        preferences.getConnectionCount()
    }

    func getPortList(protocolName: String) -> [String]? {
        let portMap = (try? portMap.value()) ?? []
        return portMap.first(where: { $0.heading == protocolName })?.ports.toArray()
    }

    func updatePreferred(port: String, and proto: String, for network: WifiNetwork) {
        localDatabase.updateWifiNetwork(network: network,
                                        properties: [
                                            Fields.WifiNetwork.preferredProtocol: proto,
                                            Fields.WifiNetwork.preferredPort: port,
                                        ])
    }

    func updatePreferredProtocolSwitch(network: WifiNetwork, preferredProtocolStatus: Bool) {
        localDatabase.updateNetworkWithPreferredProtocolSwitch(network: network, status: preferredProtocolStatus)
    }

    func updateTrustNetworkSwitch(network: WifiNetwork, status: Bool) {
        localDatabase.updateTrustNetwork(network: network, status: status)
    }

    func loadServerList() {
        serverRepository.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
    }

    func getStaticIp() -> [StaticIP] {
        return localDatabase.getStaticIPs() ?? []
    }

    func daysSinceLogin() -> Int {
        let dateLoggedIn = preferences.getLoginDate() ?? Date()
        let today = Date()
        return today.interval(ofComponent: .day, fromDate: dateLoggedIn)
    }

    func showRateDialog() -> Bool {
        if let dateLastShown = preferences.getWhenRateUsPopupDisplayed() {
            logger.logD(self, "Date last rate dialog shown is : \(dateLastShown)")
            let today = Date()
            logger.logD(self, "Time elapsed since last rate dialog shown is \(today.interval(ofComponent: .day, fromDate: dateLastShown))")
            return today.interval(ofComponent: .day, fromDate: dateLastShown) > 30
        } else {
            return true
        }
    }

    func isPrivacyPopupAccepted() -> Bool {
        return preferences.getPrivacyPopupAccepted() ?? false
    }

    func isAntiCensorshipEnabled() -> Bool {
        return preferences.isCircumventCensorshipEnabled()
    }

    var isBlurStaticIpAddress: Bool {
        return preferences.getBlurStaticIpAddress() ?? false
    }

    func markBlurStaticIpAddress(isBlured: Bool) {
        preferences.saveBlurStaticIpAddress(bool: isBlured)
    }

    var isBlurNetworkName: Bool {
        return preferences.getBlurNetworkName() ?? false
    }

    func markBlurNetworkName(isBlured: Bool) {
        preferences.saveBlurNetworkName(bool: isBlured)
    }

    func getCustomConfig(customConfigID: String?) -> CustomConfigModel? {
        guard let id = customConfigID else { return nil }
        return localDatabase.getCustomConfigs().first { $0.id == id }?.getModel()
    }

    func refreshProtocolInfo() {
        refreshProtocolTrigger.onNext(())
    }

    func reconnect() {
        vpnManager.keepConnectingState = vpnManager.isConnected() || vpnManager.isConnecting()
        vpnManager.resetProfiles {
            let isOnline: Bool = ((try? self.appNetwork.value().status == .connected) != nil)
            if isOnline {
                self.vpnManager.delegate?.setConnecting()
                self.vpnManager.retryWithNewCredentials = true
                self.vpnManager.configureAndConnectVPN()
            }
        }
    }
}

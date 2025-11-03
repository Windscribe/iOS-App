//
//  MainViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 18/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine
import StoreKit

protocol MainViewModelType {
    var serverList: BehaviorSubject<[ServerModel]> { get }
    var lastConnection: BehaviorSubject<VPNConnection?> { get }
    var portMapHeadings: BehaviorSubject<[String]?> { get }
    var favouriteList: BehaviorSubject<[GroupModel]?> { get }
    var staticIPs: BehaviorSubject<[StaticIP]?> { get }
    var customConfigs: BehaviorSubject<[CustomConfig]?> { get }
    var oldSession: OldSession? { get }
    var locationOrderBy: BehaviorSubject<String> { get }
    var latencies: BehaviorSubject<[PingData]> { get }
    var notices: CurrentValueSubject<[Notice], Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var selectedProtocol: BehaviorSubject<String> { get }
    var selectedPort: BehaviorSubject<String> { get }
    var connectionMode: BehaviorSubject<String> { get }
    var appNetwork: BehaviorSubject<AppNetwork> { get }
    var wifiNetwork: BehaviorSubject<WifiNetwork?> { get }
    var session: BehaviorSubject<Session?> { get }
    var favouriteGroups: BehaviorSubject<[GroupModel]> { get }

    var showNetworkSecurityTrigger: PassthroughSubject<Void, Never> { get }
    var showNotificationsTrigger: PassthroughSubject<Void, Never> { get }
    var becameActiveTrigger: PassthroughSubject<Void, Never> { get }
    var updateSSIDTrigger: PublishSubject<Void> { get }
    var showProtocolSwitchTrigger: PublishSubject<Void> { get }
    var showAllProtocolsFailedTrigger: PublishSubject<Void> { get }

    var didShowBannedProfilePopup: Bool { get set }
    var didShowOutOfDataPopup: Bool { get set }
    var didShowProPlanExpiredPopup: Bool { get set }

    var promoPayload: BehaviorSubject<PushNotificationPayload?> { get }
    func loadServerList()
    func sortServerListUsingUserPreferences(ignoreStreaming: Bool, isForStreaming: Bool, servers: [ServerModel], completion: @escaping (_ result: [ServerSection]) -> Void)
    func loadPortMap()
    func loadStaticIPLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func loadCustomConfigLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func checkForUnreadNotifications(completion: @escaping (_ showNotifications: Bool, _ readNoticeDifferentCount: Int) -> Void)
    func saveLastNotificationTimestamp()
    func getLastNotificationTimestamp() -> Double?
    func sortFavouriteNodesUsingUserPreferences(favList: [GroupModel]) -> [GroupModel]
    func getStaticIp() -> [StaticIP]
    func getLatency(ip: String?) -> Int
    func isPrivacyPopupAccepted() -> Bool
    func updatePreferredProtocolSwitch(network: WifiNetwork, preferredProtocolStatus: Bool)
    func updateTrustNetworkSwitch(network: WifiNetwork, status: Bool)
    func getCustomConfig(customConfigID: String?) -> CustomConfigModel?

    func updatePreferred(port: String, and proto: String, for network: WifiNetwork)
    func updateSSID()
    func getServerModel(from groupId: Int) -> ServerModel?
    func runHapticFeedback(level: HapticFeedbackLevel)
}

class MainViewModel: MainViewModelType {
    let lookAndFeelRepository: LookAndFeelRepositoryType
    let localDatabase: LocalDatabase
    let vpnManager: VPNManager
    let logger: FileLogger
    let serverRepository: ServerRepository
    let portMapRepo: PortMapRepository
    let staticIpRepository: StaticIpRepository
    let preferences: Preferences
    let latencyRepo: LatencyRepository
    let connectivity: ConnectivityManager
    let pushNotificationsManager: PushNotificationManager!
    let notificationsRepo: NotificationRepository!
    let credentialsRepository: CredentialsRepository
    let livecycleManager: LivecycleManagerType
    let locationsManager: LocationsManager
    let protocolManager: ProtocolManagerType
    let hapticFeedbackManager: HapticFeedbackManager

    let serverList = BehaviorSubject<[ServerModel]>(value: [])
    var lastConnection = BehaviorSubject<VPNConnection?>(value: nil)
    var portMapHeadings = BehaviorSubject<[String]?>(value: nil)
    var favouriteList = BehaviorSubject<[GroupModel]?>(value: nil)
    var staticIPs = BehaviorSubject<[StaticIP]?>(value: nil)
    var customConfigs = BehaviorSubject<[CustomConfig]?>(value: nil)
    var locationOrderBy = BehaviorSubject<String>(value: DefaultValues.orderLocationsBy)
    let latencies = BehaviorSubject<[PingData]>(value: [])
    var notices = CurrentValueSubject<[Notice], Never>([])
    var selectedProtocol = BehaviorSubject<String>(value: DefaultValues.protocol)
    var selectedPort = BehaviorSubject<String>(value: DefaultValues.port)
    var connectionMode = BehaviorSubject<String>(value: DefaultValues.connectionMode)
    var appNetwork = BehaviorSubject<AppNetwork>(value: AppNetwork(.disconnected, networkType: .none, name: nil, isVPN: false))
    var wifiNetwork = BehaviorSubject<WifiNetwork?>(value: nil)
    var session = BehaviorSubject<Session?>(value: nil)
    var favouriteGroups = BehaviorSubject<[GroupModel]>(value: [])
    let promoPayload: BehaviorSubject<PushNotificationPayload?> = BehaviorSubject(value: nil)

    let showNetworkSecurityTrigger: PassthroughSubject<Void, Never>
    let showNotificationsTrigger: PassthroughSubject<Void, Never>
    let becameActiveTrigger: PassthroughSubject<Void, Never>
    let updateSSIDTrigger = PublishSubject<Void>()
    let showProtocolSwitchTrigger = PublishSubject<Void>()
    let showAllProtocolsFailedTrigger = PublishSubject<Void>()

    var oldSession: OldSession? { localDatabase.getOldSession() }

    var didShowBannedProfilePopup = false
    var didShowProPlanExpiredPopup = false
    var didShowOutOfDataPopup = false

    let isDarkMode: CurrentValueSubject<Bool, Never>

    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    init(localDatabase: LocalDatabase,
         vpnManager: VPNManager,
         logger: FileLogger,
         serverRepository: ServerRepository,
         portMapRepo: PortMapRepository,
         staticIpRepository: StaticIpRepository,
         preferences: Preferences,
         latencyRepo: LatencyRepository,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         pushNotificationsManager: PushNotificationManager,
         notificationsRepo: NotificationRepository,
         credentialsRepository: CredentialsRepository,
         connectivity: ConnectivityManager,
         livecycleManager: LivecycleManagerType,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType,
         hapticFeedbackManager: HapticFeedbackManager) {

        self.localDatabase = localDatabase
        self.vpnManager = vpnManager
        self.logger = logger
        self.serverRepository = serverRepository
        self.portMapRepo = portMapRepo
        self.staticIpRepository = staticIpRepository
        self.preferences = preferences
        self.latencyRepo = latencyRepo
        self.lookAndFeelRepository = lookAndFeelRepository
        self.pushNotificationsManager = pushNotificationsManager
        self.notificationsRepo = notificationsRepo
        self.credentialsRepository = credentialsRepository
        self.connectivity = connectivity
        self.livecycleManager = livecycleManager
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
        self.hapticFeedbackManager = hapticFeedbackManager

        showNetworkSecurityTrigger = livecycleManager.showNetworkSecurityTrigger
        showNotificationsTrigger = livecycleManager.showNotificationsTrigger
        becameActiveTrigger = livecycleManager.becameActiveTrigger

        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        loadNotifications()
        loadServerList()
        loadFavourite()
        loadTvFavourites()
        loadStaticIps()
        loadCustomConfigs()
        observeNetworkStatus()
        observeWifiNetwork()
        observeSession()
        preferences.getOrderLocationsBy()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] order in
                guard let self = self else { return }
                self.locationOrderBy.onNext(order ?? DefaultValues.orderLocationsBy)
            }
            .store(in: &cancellables)
        loadLastConnection()
        loadLatencies()
        getNotices()
        preferences.getSelectedProtocol()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.selectedProtocol.onNext(data ?? DefaultValues.protocol)
            }
            .store(in: &cancellables)
        preferences.getSelectedPort()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.selectedPort.onNext(data ?? DefaultValues.port)
            }
            .store(in: &cancellables)
        preferences.getConnectionMode()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.connectionMode.onNext(data ?? DefaultValues.connectionMode)
            }
            .store(in: &cancellables)

        serverRepository.updatedServerModelsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.serverList.onNext(data)
            }
            .store(in: &cancellables)

        protocolManager.showProtocolSwitchTrigger
            .sink { [weak self] _ in
                self?.showProtocolSwitchTrigger.onNext(())
            }
            .store(in: &cancellables)

        protocolManager.showAllProtocolsFailedTrigger
            .sink { [weak self] _ in
                self?.showAllProtocolsFailedTrigger.onNext(())
            }
            .store(in: &cancellables)

    }

    private func observeWifiNetwork() {
        Publishers.CombineLatest(localDatabase.getPublishedNetworks(), connectivity.network.eraseToAnyPublisher())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] (networks, appNetwork) in
                guard let self = self else { return }
                guard let matchingNetwork = networks.first(where: {
                    $0.isInvalidated == false && $0.SSID == appNetwork.name
                }) else { return }
                self.wifiNetwork.onNext(matchingNetwork)
            })
            .store(in: &cancellables)
    }

    private func observeSession() {
        localDatabase.getSession().subscribe(onNext: { [weak self] session in
            guard let self = self else { return }
            self.session.onNext(session)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func observeNetworkStatus() {
        connectivity.network
            .sink { [weak self] network in
                guard let self = self else { return }
                self.appNetwork.onNext(network)
            }
            .store(in: &cancellables)
    }

    func sortFavouriteNodesUsingUserPreferences(favList: [GroupModel]) -> [GroupModel] {
        var favNodesOrdered = [GroupModel]()
        switch try? locationOrderBy.value() {
        case Fields.Values.geography, Fields.Values.alphabet:
            favNodesOrdered = favList.sorted {
                if $0.city == $1.city {
                    return $0.nick < $1.nick
                } else {
                    return $0.city < $1.city
                }
            }
        case Fields.Values.latency:
            favNodesOrdered = favList.sorted { fav1, fav2 -> Bool in
                let firstLatency = getLatency(ip: fav1.pingIp)
                let secondLatency = getLatency(ip: fav2.pingIp)
                return firstLatency < secondLatency
            }
        default:
            return favList
        }
        return favNodesOrdered
    }

    func getLatency(ip: String? = nil) -> Int {
        return latencyRepo.getPingData(ip: ip ?? "")?.latency ?? -1
    }

    func sortServerListUsingUserPreferences(ignoreStreaming: Bool, isForStreaming: Bool, servers: [ServerModel], completion: @escaping (_ result: [ServerSection]) -> Void) {
        DispatchQueue.main.async {
            var serverSections = [ServerSection]()
            var serverSectionsOrdered = [ServerSection]()
            if servers.count == 0 {
                completion(serverSectionsOrdered)
                return
            }

            if ignoreStreaming {
                serverSections = servers.map { ServerSection(server: $0, collapsed: true) }
            } else {
                serverSections = servers.filter { $0.isForStreaming() == isForStreaming }.map { ServerSection(server: $0, collapsed: true) }
            }

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
            let sortedServerModel = ServerModel(id: serverModel.id, name: serverModel.name, countryCode: serverModel.countryCode, status: serverModel.status, premiumOnly: serverModel.premiumOnly, dnsHostname: serverModel.dnsHostname, groups: sortedGroups, locType: serverModel.locType, p2p: serverModel.p2p, wasEdited: serverModel.wasEdited)
            return ServerSection(server: sortedServerModel, collapsed: $0.collapsed)
        }
    }

    func loadLastConnection() {
        localDatabase.getLastConnection().subscribe(onNext: { [weak self] data in
            guard let self = self else { return }
            self.lastConnection.onNext(data)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func loadPortMap() {
        Task { @MainActor in
            let headings = self.localDatabase.getPortMap()?.map { $0.heading } ?? []
            self.portMapHeadings.onNext(headings)
        }
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
        Publishers.CombineLatest(preferences.observeFavouriteIds(), serverList.toPublisher().replaceError(with: []))
            .map { ids, servers in
                ids.compactMap { id in self.getFavouriteGroup(id: id, servers: servers) }
            }
            .receive(on: DispatchQueue.main)
            .sink { groups in
                self.favouriteGroups.onNext(groups)
            }
            .store(in: &cancellables)
    }

    func loadFavourite() {
        Publishers.CombineLatest(
            serverRepository.updatedServerModelsSubject,
            localDatabase.getFavouriteListObservable().toPublisher().replaceError(with: [])
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (serverModels, favList) in
            guard let self = self else { return }
            let favGroupModels = favList.filter { !$0.isInvalidated }
                .compactMap { favNode in
                    return serverModels.flatMap { $0.groups }
                        .first { "\($0.id)" == favNode.id }
                }
            favouriteList.onNext(favGroupModels)
        }
        .store(in: &cancellables)
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
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                self.customConfigs.onNext(data)
                self.updateCustomConfigLatency()
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
        latencyRepo.loadLatency()
        latencyRepo.latency.bind(onNext: { [weak self] data in
            guard let self = self else { return }
            self.latencies.onNext(data)
        }).disposed(by: disposeBag)
    }

    func getNotices() {
        Publishers.CombineLatest(
            localDatabase.getReadNoticesObservable().toPublisher().replaceError(with: []),
            localDatabase.getNotificationsObservable().toPublisher().replaceError(with: [])
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (_, notifications) in
            guard let self = self else { return }
            self.notices.send(notifications)
        }
        .store(in: &cancellables)
    }

    func checkForUnreadNotifications(completion: @escaping (_ showNotifications: Bool, _ readNoticeDifferentCount: Int) -> Void) {
        logger.logD("MainViewController", "Checking for unread notifications.")
        DispatchQueue.main.async {
            guard let readNotices = self.localDatabase.getReadNotices(), let notices = self.retrieveNotifications(), let notice = notices.first, let noticeId = notice.id, let noticePopup = notice.popup else { return }
            let readNoticeIds = Set(readNotices.filter { $0.isInvalidated == false }.map {  $0.id })
            let noticeIds = Set(notices.compactMap { $0.id })

            if noticePopup && !readNoticeIds.contains(noticeId) {
                self.logger.logD("MainViewController", "New notification to read with popup.")
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
        let notices = notices.value
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
        pushNotificationsManager.notification
            .compactMap { $0 }
            .sink {
                self.promoPayload.onNext($0)
            }
            .store(in: &cancellables)
        notices = notificationsRepo.notices
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
        Task {
            _ = try? await serverRepository.getUpdatedServers()
        }
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

    func runHapticFeedback(level: HapticFeedbackLevel) {
        hapticFeedbackManager.run(level: level)
    }
}

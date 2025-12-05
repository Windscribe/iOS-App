//
//  MainViewModelImpl.swift
//  Windscribe
//
//  Created by Bushra Sagir on 18/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine
import StoreKit

class MainViewModelImpl: MainViewModel {
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
    private let userSessionRepository: UserSessionRepository
    private let sessionManager: SessionManager

    let serverList = BehaviorSubject<[ServerModel]>(value: [])
    var lastConnection = BehaviorSubject<VPNConnection?>(value: nil)
    var portMapHeadings = BehaviorSubject<[String]?>(value: nil)
    var favouriteList = BehaviorSubject<[FavouriteGroupModel]?>(value: nil)
    var staticIPs = BehaviorSubject<[StaticIP]?>(value: nil)
    var customConfigs = BehaviorSubject<[CustomConfig]?>(value: nil)
    var locationOrderBy = BehaviorSubject<String>(value: DefaultValues.orderLocationsBy)
    let latencies = BehaviorSubject<[PingData]>(value: [])
    var notices = CurrentValueSubject<[Notice], Never>([])
    private var isFirstNotificationCheck = true  // Skip auto-show on first check (stale database data)
    var selectedProtocol = BehaviorSubject<String>(value: DefaultValues.protocol)
    var selectedPort = BehaviorSubject<String>(value: DefaultValues.port)
    var connectionMode = BehaviorSubject<String>(value: DefaultValues.connectionMode)
    var appNetwork = BehaviorSubject<AppNetwork>(value: AppNetwork(.disconnected, networkType: .none, name: nil, isVPN: false))
    var wifiNetwork = BehaviorSubject<WifiNetwork?>(value: nil)
    var sessionModel = CurrentValueSubject<SessionModel?, Never>(nil)
    var favouriteGroups = BehaviorSubject<[GroupModel]>(value: [])
    let promoPayload: BehaviorSubject<PushNotificationPayload?> = BehaviorSubject(value: nil)

    let showNetworkSecurityTrigger: PassthroughSubject<Void, Never>
    let showNotificationsTrigger: PassthroughSubject<Void, Never>
    let becameActiveTrigger: PassthroughSubject<Void, Never>
    let bestLocationUpdated = PassthroughSubject<Void, Never>()
    let updateSSIDTrigger = PublishSubject<Void>()
    let showProtocolSwitchTrigger = PublishSubject<Void>()
    let showAllProtocolsFailedTrigger = PublishSubject<Void>()
    let showNoInternetBeforeFailoverTrigger = PublishSubject<Void>()
    var showConnectionModeTriggeer = PassthroughSubject<Void, Never>()

    var oldSession: SessionModel? { userSessionRepository.oldSessionModel }

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
         hapticFeedbackManager: HapticFeedbackManager,
         userSessionRepository: UserSessionRepository,
         sessionManager: SessionManager) {

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
        self.userSessionRepository = userSessionRepository
        self.sessionManager = sessionManager

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

        serverRepository.serverListSubject
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

        protocolManager.showNoInternetBeforeFailoverTrigger
            .sink { [weak self] _ in
                self?.showNoInternetBeforeFailoverTrigger.onNext(())
            }
            .store(in: &cancellables)

        protocolManager.showConnectionModeTriggeer
            .sink { [weak self] _ in
                self?.showConnectionModeTriggeer.send(())
            }
            .store(in: &cancellables)

        locationsManager.bestLocationUpdated
            .sink { [weak self] _ in
                self?.bestLocationUpdated.send(())
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
        userSessionRepository.sessionModelSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self = self else { return }
                self.sessionModel.send(session)
            }
            .store(in: &cancellables)
    }

    func observeNetworkStatus() {
        connectivity.network
            .receive(on: DispatchQueue.main)
            .sink { [weak self] network in
                guard let self = self else { return }
                self.appNetwork.onNext(network)
            }
            .store(in: &cancellables)
    }

    func sortFavouriteNodesUsingUserPreferences(favList: [FavouriteGroupModel]) -> [FavouriteGroupModel] {
        var favNodesOrdered = [FavouriteGroupModel]()
        switch try? locationOrderBy.value() {
        case Fields.Values.geography, Fields.Values.alphabet:
            favNodesOrdered = favList.sorted {
                if $0.groupModel.city == $1.groupModel.city {
                    return $0.groupModel.nick < $1.groupModel.nick
                } else {
                    return $0.groupModel.city < $1.groupModel.city
                }
            }
        case Fields.Values.latency:
            favNodesOrdered = favList.sorted { fav1, fav2 -> Bool in
                let firstLatency = getLatency(ip: fav1.groupModel.pingIp)
                let secondLatency = getLatency(ip: fav2.groupModel.pingIp)
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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

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
                serverSectionsOrdered = self.sortServersByGeography(serverSections)
            case Fields.Values.alphabet:
                serverSectionsOrdered = self.sortServersByAlphabet(serverSections)
            case Fields.Values.latency:
                serverSectionsOrdered = self.sortServersByLatency(serverSections)
            default:
                serverSectionsOrdered = serverSections
            }
            serverSectionsOrdered = self.sortServerNodes(serverList: serverSectionsOrdered, orderBy: orderBy)
            completion(serverSectionsOrdered)
        }
    }

    private func sortServersByGeography(_ serverSections: [ServerSection]) -> [ServerSection] {
        return serverSections
    }

    private func sortServersByAlphabet(_ serverSections: [ServerSection]) -> [ServerSection] {
        return serverSections.sorted { serverSection1, serverSection2 -> Bool in
            guard let countryCode1 = serverSection1.server?.name,
                  let countryCode2 = serverSection2.server?.name else { return false }
            return countryCode1 < countryCode2
        }
    }

    private func sortServersByLatency(_ serverSections: [ServerSection]) -> [ServerSection] {
        let serversMappedWithPing = serverSections.map { serverSection -> (ServerSection, Int) in
            guard let hostnames = serverSection.server?.groups.filter({$0.pingIp != ""}).map({$0.pingIp}) else {
                return (serverSection, -1)
            }
            let nodeList = hostnames.compactMap({
                let latency = self.latencyRepo.getPingData(ip: $0)?.latency
                return latency == -1 ? nil : latency
            })
            guard nodeList.count != 0 else { return (serverSection, -1) }

            // Use lowest latency instead of average for more accurate region ranking
            let latency = nodeList.min() ?? -1
            guard latency != 0 else { return (serverSection, -1) }
            return (serverSection, latency)
        }

        let serverMappedSorted = serversMappedWithPing.sorted { (serverSection1, serverSection2) -> Bool in
            guard serverSection1.1 > 0 else { return false }
            guard serverSection2.1 > 0 else { return true }
            return serverSection1.1 < serverSection2.1
        }

        return serverMappedSorted.map { $0.0 }
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
            let sortedServerModel = serverModel.copyModelWith(newGroups: sortedGroups)
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
        servers.flatMap { $0.groups }
            .first { $0.id == Int(id) }
    }

    private func loadTvFavourites() {
        Publishers.CombineLatest(preferences.observeFavouriteIds(), serverList.toPublisher().replaceError(with: []))
            .map { ids, servers in
                ids.compactMap { id in self.getFavouriteGroup(id: id, servers: servers) }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groups in
                self?.favouriteGroups.onNext(groups)
            }
            .store(in: &cancellables)
    }

    func loadFavourite() {
        serverRepository.serverListSubject.combineLatest(
            localDatabase.getFavouriteListObservable()
                .toPublisherIncludingEmpty()
                .replaceError(with: []))
        .receive(on: RunLoop.main)
        .sink { [weak self] (serverModels, favList) in
            guard let self = self else { return }
            let favGroupModels = favList.filter { !$0.isInvalidated }
                .compactMap { favNode in
                    return serverModels.flatMap { $0.groups }
                        .first { "\($0.id)" == favNode.id }
                        .map { FavouriteGroupModel(favourite: favNode, groupModel: $0)}
                }
            favouriteList.onNext(favGroupModels)
        }
        .store(in: &cancellables)
    }

    func loadStaticIps() {
        Task { @MainActor in
            do {
                let data = try await staticIpRepository.getStaticServers()
                staticIPs.onNext(data)
            } catch {
                logger.logE("MainViewModel", "Failed to load static IPs: \(error)")
            }
        }
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
        serverRepository.serverListSubject
            .first(where: { !$0.isEmpty })
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.latencyRepo.loadLatency()
            }
            .store(in: &cancellables)

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
            guard let readNotices = self.localDatabase.getReadNotices() else {
                return
            }
            guard let notices = self.retrieveNotifications() else {
                return
            }
            guard let notice = notices.first else {
                return
            }
            guard let noticeId = notice.id, let noticePopup = notice.popup else {
                return
            }

            let readNoticeIds = Set(readNotices.filter { $0.isInvalidated == false }.map {  $0.id })
            let noticeIds = Set(notices.compactMap { $0.id })

            // Only auto-show on fresh API data (skip first check with stale database data)
            if !self.isFirstNotificationCheck && noticePopup && !readNoticeIds.contains(noticeId) {
                self.logger.logD("MainViewController", "New notification to read with popup.")
                completion(true, 0)
                return
            }

            // Always update badge count (even on first check)
            let readNoticeDifferentCount = noticeIds.reduce(0) {
                $0 + (!readNoticeIds.contains($1) ? 1 : 0)
            }

            if readNoticeDifferentCount != 0 {
                self.pushNotificationsManager.setNotificationCount(count: readNoticeDifferentCount)
            } else {
                self.pushNotificationsManager.setNotificationCount(count: 0)
            }

            // Mark first check as complete
            if self.isFirstNotificationCheck {
                self.isFirstNotificationCheck = false
            }

            completion(false, readNoticeDifferentCount)
        }
    }

    func retrieveNotifications() -> [NoticeModel]? {
        let notices = notices.value
        if notices.filter({$0.isInvalidated}).count > 0 {
            return nil
        }
        // Sort by date (descending) to match NewsFeedViewModel sorting, take 5 newest
        let noticeModels = Array(notices.compactMap { $0.getModel() }.reversed().sorted(by: { $0.date! > $1.date! }).prefix(5))
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
            .sink { [weak self] in
                self?.promoPayload.onNext($0)
            }
            .store(in: &cancellables)

        // Subscribe to repository notices and forward to our subject
        // Don't skip - we need initial data for badge count
        notificationsRepo.notices
            .sink { [weak self] notifications in
                self?.notices.send(notifications)
            }
            .store(in: &cancellables)
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
            try? await serverRepository.updatedServers()
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

    func checkAccountWasDowngraded(for serverList: [ServerModel]) -> Bool {
        if let oldSession = oldSession,
           let newSession = userSessionRepository.sessionModel {
            let groups = serverList.compactMap { $0.groups }.flatMap { $0 }
            let nodes = groups.compactMap { $0.nodes }.flatMap { $0 }
            if oldSession.isPremium &&
                !newSession.isPremium &&
                !nodes.isEmpty {
                logger.logD("MainViewModel", "Account downgrade detected.")
               return true
            }
        }

       return false
    }

    func keepSessionUpdated() {
        sessionManager.keepSessionUpdated()
    }
}

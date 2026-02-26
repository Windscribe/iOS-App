//
//  MainViewModelImpl.swift
//  Windscribe
//
//  Created by Bushra Sagir on 18/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine
import StoreKit

class MainViewModelImpl: MainViewModel {
    let lookAndFeelRepository: LookAndFeelRepositoryType
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
    private let wifiNetworkRepository: WifiNetworkRepository
    private let customConfigRepository: CustomConfigRepository
    private let alertManager: AlertManager
    private let wifiManager: WifiManager

    let serverList = CurrentValueSubject<[ServerModel], Never>([])
    var portMapHeadings = CurrentValueSubject<[String]?, Never>(nil)
    var favouriteList = CurrentValueSubject<[FavouriteGroupModel]?, Never>(nil)
    var staticIPs = CurrentValueSubject<[StaticIPModel]?, Never>(nil)
    var locationOrderBy = CurrentValueSubject<String, Never>(DefaultValues.orderLocationsBy)
    let latencies = CurrentValueSubject<[PingDataModel], Never>([])
    var notices = CurrentValueSubject<[NoticeModel], Never>([])
    private var isFirstNotificationCheck = true  // Skip auto-show on first check (stale database data)
    var selectedProtocol = CurrentValueSubject<String, Never>(DefaultValues.protocol)
    var selectedPort = CurrentValueSubject<String, Never>(DefaultValues.port)
    var connectionMode = CurrentValueSubject<String, Never>(DefaultValues.connectionMode)
    var appNetwork = CurrentValueSubject<AppNetwork, Never>(AppNetwork(.disconnected, networkType: .none, name: nil, isVPN: false))
    var wifiNetwork = CurrentValueSubject<WifiNetworkModel?, Never>(nil)
    var sessionModel = CurrentValueSubject<SessionModel?, Never>(nil)
    var favouriteGroups = CurrentValueSubject<[GroupModel], Never>([])
    let promoPayload = CurrentValueSubject<PushNotificationPayload?, Never>(nil)

    let customConfigs = CurrentValueSubject<[CustomConfigModel], Never>([])
    let showNetworkSecurityTrigger: PassthroughSubject<Void, Never>
    let showNotificationsTrigger: PassthroughSubject<Void, Never>
    let becameActiveTrigger: PassthroughSubject<Void, Never>
    let updateSSIDTrigger = PassthroughSubject<Void, Never>()
    let showProtocolSwitchTrigger = PassthroughSubject<Void, Never>()
    let showAllProtocolsFailedTrigger = PassthroughSubject<Void, Never>()
    let showNoInternetBeforeFailoverTrigger = PassthroughSubject<Void, Never>()
    var showConnectionModeTriggeer = PassthroughSubject<Void, Never>()
    var disconnectConnectionTrigger = PassthroughSubject<Void, Never>()

    var oldSession: SessionModel? { userSessionRepository.oldSessionModel }

    var didShowBannedProfilePopup = false
    var didShowProPlanExpiredPopup = false
    var didShowOutOfDataPopup = false

    let isDarkMode: CurrentValueSubject<Bool, Never>

    private var cancellables = Set<AnyCancellable>()

    init(vpnManager: VPNManager,
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
         wifiNetworkRepository: WifiNetworkRepository,
         sessionManager: SessionManager,
         customConfigRepository: CustomConfigRepository,
         alertManager: AlertManager,
         wifiManager: WifiManager) {

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
        self.wifiNetworkRepository = wifiNetworkRepository
        self.customConfigRepository = customConfigRepository
        self.alertManager = alertManager
        self.wifiManager = wifiManager

        showNetworkSecurityTrigger = livecycleManager.showNetworkSecurityTrigger
        showNotificationsTrigger = livecycleManager.showNotificationsTrigger
        becameActiveTrigger = livecycleManager.becameActiveTrigger

        isDarkMode = lookAndFeelRepository.isDarkModeSubject

        // Save current WiFi networks on initialization
        wifiManager.saveCurrentWifiNetworks()

        loadNotifications()
        loadServerList()
        loadFavourite()
        loadTvFavourites()
        loadCustomConfigs()
        observeNetworkStatus()
        observeWifiNetwork()
        observeSession()
        preferences.getOrderLocationsBy()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] order in
                guard let self = self else { return }
                self.locationOrderBy.send(order ?? DefaultValues.orderLocationsBy)
            }
            .store(in: &cancellables)
        loadLatencies()
        getNotices()
        preferences.getSelectedProtocol()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.selectedProtocol.send(data ?? DefaultValues.protocol)
            }
            .store(in: &cancellables)
        preferences.getSelectedPort()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.selectedPort.send(data ?? DefaultValues.port)
            }
            .store(in: &cancellables)
        preferences.getConnectionMode()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.connectionMode.send(data ?? DefaultValues.connectionMode)
            }
            .store(in: &cancellables)

        serverRepository.serverListSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.serverList.send(data)
            }
            .store(in: &cancellables)

        protocolManager.showProtocolSwitchTrigger
            .sink { [weak self] _ in
                self?.showProtocolSwitchTrigger.send(())
            }
            .store(in: &cancellables)

        protocolManager.showAllProtocolsFailedTrigger
            .sink { [weak self] _ in
                self?.showAllProtocolsFailedTrigger.send(())
            }
            .store(in: &cancellables)

        protocolManager.showNoInternetBeforeFailoverTrigger
            .sink { [weak self] _ in
                self?.showNoInternetBeforeFailoverTrigger.send(())
            }
            .store(in: &cancellables)

        protocolManager.showConnectionModeTriggeer
            .sink { [weak self] _ in
                self?.showConnectionModeTriggeer.send(())
            }
            .store(in: &cancellables)

        protocolManager.disconnectConnectionTrigger
            .sink { [weak self] _ in
                self?.disconnectConnectionTrigger.send(())
            }
            .store(in: &cancellables)
    }

    private func observeWifiNetwork() {
        wifiNetworkRepository.networks.combineLatest(connectivity.network.eraseToAnyPublisher())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (networks, appNetwork) in
                guard let self = self else { return }
                guard let matchingNetwork = networks.first(where: {
                    $0.SSID == appNetwork.name
                }) else { return }
                self.wifiNetwork.send(matchingNetwork)
            }
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
                self.appNetwork.send(network)
            }
            .store(in: &cancellables)
    }

    func sortFavouriteNodesUsingUserPreferences(favList: [FavouriteGroupModel]) -> [FavouriteGroupModel] {
        var favNodesOrdered = [FavouriteGroupModel]()
        switch locationOrderBy.value {
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

    func sortServerListUsingUserPreferences(ignoreStreaming: Bool, isForStreaming: Bool, servers: [ServerModel]) -> [ServerSection]{
        var serverSections = [ServerSection]()
        var serverSectionsOrdered = [ServerSection]()
        if servers.count == 0 {
            return []
        }

        if ignoreStreaming {
            serverSections = servers.map { ServerSection(server: $0, collapsed: true) }
        } else {
            serverSections = servers.filter { $0.isForStreaming() == isForStreaming }.map { ServerSection(server: $0, collapsed: true) }
        }

        let orderBy = locationOrderBy.value

        switch orderBy {
        case Fields.Values.geography:
            serverSectionsOrdered = sortServersByGeography(serverSections)
        case Fields.Values.alphabet:
            serverSectionsOrdered = sortServersByAlphabet(serverSections)
        case Fields.Values.latency:
            serverSectionsOrdered = sortServersByLatency(serverSections)
        default:
            serverSectionsOrdered = serverSections
        }
        serverSectionsOrdered = sortServerNodes(serverList: serverSectionsOrdered, orderBy: orderBy)
        return serverSectionsOrdered
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

    func loadPortMap() {
        Task { @MainActor in
            let headings = self.portMapRepo.currentPortMaps.map { $0.heading }
            self.portMapHeadings.send(headings)
        }
    }

    private func getFavouriteGroup(id: String, servers: [ServerModel]) -> GroupModel? {
        servers.flatMap { $0.groups }
            .first { $0.id == Int(id) }
    }

    private func loadTvFavourites() {
        Publishers.CombineLatest(preferences.observeFavouriteIds(), serverList)
            .map { ids, servers in
                ids.compactMap { id in self.getFavouriteGroup(id: id, servers: servers) }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groups in
                self?.favouriteGroups.send(groups)
            }
            .store(in: &cancellables)
    }

    func loadFavourite() {
        serverRepository.serverListSubject.combineLatest(
            serverRepository.favouriteListSubject)
        .receive(on: RunLoop.main)
        .sink { [weak self] (serverModels, favList) in
            guard let self = self else { return }
            let favGroupModels = favList
                .compactMap { favNode in
                    return serverModels.flatMap { $0.groups }
                        .first { "\($0.id)" == favNode.id }
                        .map { FavouriteGroupModel(favourite: favNode, groupModel: $0)}
                }
            favouriteList.send(favGroupModels)
        }
        .store(in: &cancellables)
    }

    func loadStaticIps() {
        Task { @MainActor in
            do {
                try await staticIpRepository.updateStaticServers()
                staticIPs.send(staticIpRepository.staticIPs)
            } catch {
                logger.logE("MainViewModel", "Failed to load static IPs: \(error)")
            }
        }
    }

    func loadCustomConfigs() {
        customConfigRepository.customConfigs
            .sink { [weak self] data in
                guard let self = self else { return }
                self.customConfigs.send(data)
                // Latency for custom configs will be loaded on manual refresh or when tab is opened
            }
            .store(in: &cancellables)
    }

    func updateCustomConfigLatency() {
        Task {
            await latencyRepo.loadCustomConfigLatency()
        }
    }

    func loadStaticIPLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void) {
        Task {
            await latencyRepo.loadStaticIpLatency()
            completion(true, nil)
        }
    }

    func loadCustomConfigLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void) {
        Task {
            await latencyRepo.loadCustomConfigLatency()
            completion(true, nil)
        }
    }

    func loadLatencies() {
        serverRepository.serverListSubject
            .first(where: { !$0.isEmpty })
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    try? await self.latencyRepo.loadLatency()
                }
            }
            .store(in: &cancellables)

        latencyRepo.latency
            .sink { [weak self] data in
                guard let self = self else { return }
                self.latencies.send(data)
            }
            .store(in: &cancellables)
    }

    func getNotices() {
        Publishers.CombineLatest(
            notificationsRepo.readNotices,
            notificationsRepo.notices
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
            let notices = self.retrieveNotifications()
            guard let notice = notices.first else { return }

            let readNoticeIds = self.notificationsRepo.readNotices.value
            let noticeIds = Set(notices.compactMap { $0.id })

            // Only auto-show on fresh API data (skip first check with stale database data)
            if !self.isFirstNotificationCheck && notice.popup && !readNoticeIds.contains(notice.id) {
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

    func retrieveNotifications() -> [NoticeModel] {
        let notices = notices.value
        // Sort by date (descending) to match NewsFeedViewModel sorting, take 5 newest
        return Array(notices.reversed().sorted(by: { $0.date > $1.date }).prefix(5))
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
                self?.promoPayload.send($0)
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

    func updatePreferred(port: String, and proto: String, for network: WifiNetworkModel) async {
        wifiNetworkRepository.updateNetworkPreferredProtocol(network: network, protocol: proto, port: port)
    }

    func updatePreferredProtocolSwitch(network: WifiNetworkModel, preferredProtocolStatus: Bool) {
        wifiNetworkRepository.updateNetworkPreferredProtocolStatus(network: network, status: preferredProtocolStatus)
    }

    func updateTrustNetworkSwitch(network: WifiNetworkModel, status: Bool) {
        wifiNetworkRepository.updateNetworkTrustStatus(network: network, trusted: status)
    }

    func loadServerList() {
        Task {
            try? await serverRepository.updatedServers()
            // Load static IPs after server list completes to avoid parallel API calls
            try? await staticIpRepository.updateStaticServers()
            staticIPs.send(staticIpRepository.staticIPs)
        }
    }

    func getStaticIp() -> [StaticIPModel] {
        return staticIpRepository.staticIPs
    }

    func isPrivacyPopupAccepted() -> Bool {
        return preferences.getPrivacyPopupAccepted() ?? false
    }

    func getCustomConfig(customConfigID: String?) -> CustomConfigModel? {
        guard let id = customConfigID else { return nil }
        return customConfigRepository.getCustomConfig(fileId: id)
    }

    func updateSSID() {
        updateSSIDTrigger.send(())
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

    func showSimpleAlert(viewController: UIViewController?, title: String, message: String, buttonText: String) {
        alertManager.showSimpleAlert(viewController: viewController,
                                     title: title,
                                     message: message,
                                     buttonText: buttonText)
    }

    func showAlert(title: String, message: String, actions: [UIAlertAction]) {
        alertManager.showAlert(title: title, message: message, actions: actions)
    }
}

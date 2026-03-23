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
    let locationListRepository: LocationListRepository
    let portMapRepo: PortMapRepository
    let staticIpRepository: StaticIpRepository
    let preferences: Preferences
    let latencyRepo: LatencyRepository
    let connectivity: ConnectivityManager
    let pushNotificationsManager: PushNotificationManager!
    let notificationsRepo: NotificationRepository!
    let credentialsRepository: CredentialsRepository
    let lifecycleManager: LifecycleManagerType
    let locationsManager: LocationsManager
    let protocolManager: ProtocolManagerType
    let hapticFeedbackManager: HapticFeedbackManager
    private let userSessionRepository: UserSessionRepository
    private let sessionManager: SessionManager
    private let wifiNetworkRepository: WifiNetworkRepository
    private let customConfigRepository: CustomConfigRepository
    private let alertManager: AlertManager
    private let wifiManager: WifiManager

    let serverList = CurrentValueSubject<[ServerMachineModel], Never>([])
    let locationsList = CurrentValueSubject<[LocationModel], Never>([])
    var portMapHeadings = CurrentValueSubject<[String]?, Never>(nil)
    var favouriteList = CurrentValueSubject<[FavoriteDatacenterlModel]?, Never>(nil)
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
    var favouriteDatacenters = CurrentValueSubject<[DatacenterModel], Never>([])
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
         locationListRepository: LocationListRepository,
         portMapRepo: PortMapRepository,
         staticIpRepository: StaticIpRepository,
         preferences: Preferences,
         latencyRepo: LatencyRepository,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         pushNotificationsManager: PushNotificationManager,
         notificationsRepo: NotificationRepository,
         credentialsRepository: CredentialsRepository,
         connectivity: ConnectivityManager,
         lifecycleManager: LifecycleManagerType,
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
        self.locationListRepository = locationListRepository
        self.portMapRepo = portMapRepo
        self.staticIpRepository = staticIpRepository
        self.preferences = preferences
        self.latencyRepo = latencyRepo
        self.lookAndFeelRepository = lookAndFeelRepository
        self.pushNotificationsManager = pushNotificationsManager
        self.notificationsRepo = notificationsRepo
        self.credentialsRepository = credentialsRepository
        self.connectivity = connectivity
        self.lifecycleManager = lifecycleManager
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
        self.hapticFeedbackManager = hapticFeedbackManager
        self.userSessionRepository = userSessionRepository
        self.sessionManager = sessionManager
        self.wifiNetworkRepository = wifiNetworkRepository
        self.customConfigRepository = customConfigRepository
        self.alertManager = alertManager
        self.wifiManager = wifiManager

        showNetworkSecurityTrigger = lifecycleManager.showNetworkSecurityTrigger
        showNotificationsTrigger = lifecycleManager.showNotificationsTrigger
        becameActiveTrigger = lifecycleManager.becameActiveTrigger

        isDarkMode = lookAndFeelRepository.isDarkModeSubject

        // Save current WiFi networks on initialization
        wifiManager.saveCurrentWifiNetworks()

        loadNotifications()
        loadLocationList()
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

        locationListRepository.serverListSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.serverList.send(data)
            }
            .store(in: &cancellables)

        locationListRepository.locationListSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.locationsList.send(data)
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

    func sortFavouriteNodesUsingUserPreferences(favList: [FavoriteDatacenterlModel]) -> [FavoriteDatacenterlModel] {
        var favNodesOrdered = [FavoriteDatacenterlModel]()
        switch locationOrderBy.value {
        case Fields.Values.geography, Fields.Values.alphabet:
            favNodesOrdered = favList.sorted {
                if $0.datacenterModel.city == $1.datacenterModel.city {
                    return $0.datacenterModel.nick < $1.datacenterModel.nick
                } else {
                    return $0.datacenterModel.city < $1.datacenterModel.city
                }
            }
        case Fields.Values.latency:
            favNodesOrdered = favList.sorted { fav1, fav2 -> Bool in
                let firstLatency = getLatency(datacenter: fav1.datacenterModel)
                let secondLatency = getLatency(datacenter: fav2.datacenterModel)
                return firstLatency < secondLatency
            }
        default:
            return favList
        }
        return favNodesOrdered
    }

    func getLatency(datacenter: DatacenterModel) -> Int {
        let ip = datacenter.pingServer?.ip ?? ""
        return latencyRepo.getPingData(ip: ip)?.latency ?? -1
    }

    func sortLocationListUsingUserPreferences(ignoreStreaming: Bool,
                                              isForStreaming: Bool,
                                              locations: [LocationModel]) -> [LocationSection] {
        var locationSections = [LocationSection]()
        var locationSectionsOrdered = [LocationSection]()
        if locations.count == 0 {
            return []
        }
        locationSections = locations.map { LocationSection(location: $0, collapsed: true) }
        let orderBy = locationOrderBy.value

        switch orderBy {
        case Fields.Values.geography:
            locationSectionsOrdered = sortServersByGeography(locationSections)
        case Fields.Values.alphabet:
            locationSectionsOrdered = sortServersByAlphabet(locationSections)
        case Fields.Values.latency:
            locationSectionsOrdered = sortLocationsByLatency(locationSections)
        default:
            locationSectionsOrdered = locationSections
        }
        locationSectionsOrdered = sortLocationDatacenters(locationSectionsList: locationSectionsOrdered, orderBy: orderBy)
        return locationSectionsOrdered
    }

    private func sortServersByGeography(_ locationSections: [LocationSection]) -> [LocationSection] {
        return locationSections
    }

    private func sortServersByAlphabet(_ locationSections: [LocationSection]) -> [LocationSection] {
        return locationSections.sorted { locationSection1, locationSection2 -> Bool in
            guard let countryCode1 = locationSection1.location?.name,
                  let countryCode2 = locationSection2.location?.name else { return false }
            return countryCode1 < countryCode2
        }
    }

    private func sortLocationsByLatency(_ locationSections: [LocationSection]) -> [LocationSection] {
        var mappedLocations = locationSections.compactMap { section in
            if let pingServer = section.location?.datacenters.randomElement()?.pingServer,
               let latency = latencyRepo.getPingData(ip: pingServer.ip)?.latency {
                return (section, latency)
            }
            return (section, -1)
        }

        mappedLocations.sort {
            if $1.1 == -1 {
                return true
            }
            return $0.1 < $1.1
        }

        return mappedLocations.map { $0.0 }
    }

    private func sortLocationDatacenters(locationSectionsList: [LocationSection], orderBy: String) -> [LocationSection] {
        guard orderBy != Fields.Values.geography else { return locationSectionsList }
        return locationSectionsList.map {
            guard let locationModel = $0.location else { return $0 }
            var sortedDatacenters = [DatacenterModel]()
            switch orderBy {
            case Fields.Values.latency:
                sortedDatacenters = locationModel.datacenters.sorted {
                    guard let ping0 = self.latencyRepo.getPingData(ip: $0.pingServer?.ip ?? "")?.latency, ping0 != -1 else { return false }
                    guard let ping1 = self.latencyRepo.getPingData(ip: $1.pingServer?.ip ?? "")?.latency, ping1 != -1 else { return true }
                    return ping0 < ping1
                }
            default:
                sortedDatacenters = locationModel.datacenters.sorted {
                    if $0.city == $1.city {
                        return $0.nick < $1.nick
                    }
                    return $0.city < $1.city
                }
            }
            let sortedServerModel = locationModel.copyModelWith(datacenters: sortedDatacenters)
            return LocationSection(location: locationModel, collapsed: $0.collapsed)
        }
    }

    func loadPortMap() {
        Task { @MainActor in
            let headings = self.portMapRepo.currentPortMaps.map { $0.heading }
            self.portMapHeadings.send(headings)
        }
    }

    private func getFavouriteDatacenter(id: String, locations: [LocationModel]) -> DatacenterModel? {
        locations.flatMap { $0.datacenters }
            .first { $0.id == Int(id) }
    }

    private func loadTvFavourites() {
        Publishers.CombineLatest(preferences.observeFavouriteIds(), locationsList)
            .map { ids, locations in
                ids.compactMap { id in self.getFavouriteDatacenter(id: id, locations: locations) }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] datacenters in
                self?.favouriteDatacenters.send(datacenters)
            }
            .store(in: &cancellables)
    }

    func loadFavourite() {
        locationListRepository.locationListSubject.combineLatest(
            locationListRepository.favouriteListSubject)
        .receive(on: RunLoop.main)
        .sink { [weak self] (locationModels, favList) in
            guard let self = self else { return }
            let favDatacenterModels = favList
                .compactMap { favNode in
                    return locationModels.flatMap { $0.datacenters }
                        .first { "\($0.id)" == favNode.id }
                        .map { FavoriteDatacenterlModel(favourite: favNode, datacenterModel: $0)}
                }
            favouriteList.send(favDatacenterModels)
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

    func loadLocationList() {
        Task {
            try? await locationListRepository.updateLocations()
            try? await locationListRepository.updatedServerList()
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

    func getIsSelectedLocationPremium() -> Bool {
        locationsManager.getIsSelectedLocationPremium()
    }

    func getLocationModel(from datacenterId: Int) -> LocationModel? {
        try? locationsManager.getLocation(from: datacenterId).0
    }

    func runHapticFeedback(level: HapticFeedbackLevel) {
        hapticFeedbackManager.run(level: level)
    }

    func checkAccountWasDowngraded() -> Bool {
        if let oldSession = oldSession,
           let newSession = userSessionRepository.sessionModel {
            let serverList = serverList.value
            if oldSession.isPremium &&
                !newSession.isPremium &&
                !serverList.isEmpty {
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

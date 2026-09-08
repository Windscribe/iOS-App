//
//  LatencyRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Combine
import Swinject

enum TCPLatencyError: Error {
    case cancelled
    case vpnConnected
    case pingFailed
    case notIOS
}

protocol LatencyRepository {
    var latency: CurrentValueSubject<[PingDataModel], Never> { get }
    var latencyUpdatedTrigger: PassthroughSubject<Void, Never> { get }

    func getPingData(ip: String) -> PingDataModel?
    func loadLatency() async throws
    func loadQuickLatency() async throws
    func loadStaticIpLatency() async
    func loadCustomConfigLatency() async
    func pickBestLocation(pingData: [PingDataModel])
    func pickBestLocation()
    func refreshBestLocation()
    func checkLocationsValidity() async
}

class LatencyRepositoryImpl: LatencyRepository {
    private let pingManager: LocalPingManager
    private let database: LocalDatabase
    private let logger: FileLogger
    private let vpnStateRepository: VPNStateRepository
    private let locationsManager: LocationsManager
    private let preferences: Preferences
    private let advanceRepository: AdvanceRepository
    private let userSessionRepository: UserSessionRepository
    private let staticIpRepository: StaticIpRepository
    private let locationListRepository: LocationListRepository
    private let latencyLoadLock = NSLock()

    let latency = CurrentValueSubject<[PingDataModel], Never>([])
    let latencyUpdatedTrigger = PassthroughSubject<Void, Never>()

    private let favList = CurrentValueSubject<[FavouriteModel], Never>([])
    private var observingBestLocation = false
    private var cancellables = Set<AnyCancellable>()
    private var startTimeStamp = Date()
    private var hasPassedInitialTimer = false
    private var isLoadingLatency = false
    private var wasLatencyLoadCancelled = false
    private var currentLatencyTask: Task<[PingDataModel], Never>?

    init(pingManager: LocalPingManager,
         database: LocalDatabase,
         vpnStateRepository: VPNStateRepository,
         logger: FileLogger,
         locationsManager: LocationsManager,
         preferences: Preferences,
         advanceRepository: AdvanceRepository,
         userSessionRepository: UserSessionRepository,
         staticIpRepository: StaticIpRepository,
         locationListRepository: LocationListRepository) {
        self.pingManager = pingManager
        self.database = database
        self.vpnStateRepository = vpnStateRepository
        self.logger = logger
        self.locationsManager = locationsManager
        self.preferences = preferences
        self.advanceRepository = advanceRepository
        self.userSessionRepository = userSessionRepository
        self.staticIpRepository = staticIpRepository
        self.locationListRepository = locationListRepository

        latency.send(self.database.getAllPingData())
        observeFavouriteList()

        refreshBestLocation()

        let queue = DispatchQueue(label: "latency.trigger.queue")

        // Fire on pingable publishes (servers merged in), re-arming, at most once/sec.
        locationListRepository.datacenterListSubject
            .filter { $0.contains { $0.pingServer != nil } }
            .throttle(for: .seconds(1), scheduler: queue, latest: true)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                   await self.loadLatency()
                }
            }
            .store(in: &cancellables)

        // loadLatency skips while connected; refresh on the connected->disconnected transition.
        vpnStateRepository.getStatus()
            .map { $0 == .disconnected }
            .removeDuplicates()
            .dropFirst()
            .filter { $0 }
            .throttle(for: .seconds(1), scheduler: queue, latest: true)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                   await self.loadLatency()
                }
            }
            .store(in: &cancellables)

        vpnStateRepository.vpnInfo
            .compactMap { $0?.status }
            .filter { $0 != .disconnected }
            .sink { [weak self] _ in
                self?.cancelCurrentLatencyLoad()
            }
            .store(in: &cancellables)
    }

    private func observeFavouriteList() {
        database.getFavouriteListPublisher()
            .sink { favList in
                self.favList.send(favList)
            }
            .store(in: &self.cancellables)
    }

    /// Returns latency data for ip.
    func getPingData(ip: String) -> PingDataModel? {
        let value = latency.value
        return value.first { $0.ip == ip }
    }

    func loadLatency() async {
        guard beginLatencyLoad() else {
            logger.logI("LatencyRepositoryImpl", "Latency update already in progress, skipping duplicate request.")
            return
        }
        defer { finishLatencyLoad() }

        // If the app launches and the VPN is connected the app does not know straight away
        // that it is connected, we wait 1 sec until eveything is loaded an then we can
        // load the latencies, otherwise it will get the latency of the connected location
        let timeSince = Date().timeIntervalSince(startTimeStamp)
        guard timeSince >= 1 || hasPassedInitialTimer else {
            try? await Task.sleep(nanoseconds: 50_000_000)
            await loadLatency()
            return
        }
        hasPassedInitialTimer = true

        guard vpnStateRepository.isDisconnected() else {
            logger.logI("LatencyRepositoryImpl", "Latency update skipped - VPN is not disconnected.")
            return
        }

        guard await loadAllDatacentersLatency() else { return }
        latencyUpdatedTrigger.send(())
        refreshBestLocation()
    }

    func loadQuickLatency() async throws {
        logger.logI("LatencyRepositoryImpl", "Quick latency: pinging 10 nearby datacenters.")

        guard !vpnStateRepository.isConnected() else {
            logger.logI("LatencyRepositoryImpl", "Quick latency skipped - VPN is connected.")
            return
        }

        let nearbyDatacenterServers = getNearbyDatacentersPingServer(limit: 10)
        guard !nearbyDatacenterServers.isEmpty else {
            logger.logI("LatencyRepositoryImpl", "No nearby datacenters found for quick latency.")
            return
        }

        let nearbyPingTargets = nearbyDatacenterServers.map { ($0.ip, buildHostforPing(from: $0)) }
        let pingData = await createLatencyTask(from: nearbyPingTargets)
        persistPingData(pingData)
        refreshBestLocation()
        logger.logI(
            "LatencyRepositoryImpl",
            "Quick latency complete. Best location updated with \(nearbyDatacenterServers.count) datacenters."
        )
    }

    private func getNearbyDatacentersPingServer(limit: Int) -> [ServerMachineModel] {
        let datacenterList = locationListRepository.currentDatacenterModels
        let userTimeZone = TimeZone.current
        let isPremium = userSessionRepository.sessionModel?.isPremium ?? false

        let nearbyDataCenterList: [(datacenter: DatacenterModel, timeDiff: TimeInterval)] = datacenterList
            .map { datacenter in
                guard let timeZone = TimeZone(identifier: datacenter.tz) else { return (datacenter, Double(-1)) }
                let timeDifference = TimeInterval(abs(timeZone.secondsFromGMT() - userTimeZone.secondsFromGMT()))
                return (datacenter, timeDifference)
            }.filter { (datacenter, timeDifference) in
                guard !datacenter.servers.isEmpty else { return false }
                guard timeDifference > 0 else { return false }
                guard timeDifference <= 7200 else { return false }
                guard isPremium || !datacenter.isPremiumOnly else { return false }
                return true
            }

        return nearbyDataCenterList
            .sorted { $0.timeDiff < $1.timeDiff }
            .prefix(limit)
            .compactMap { $0.datacenter.pingServer }
    }

    private func loadAllDatacentersLatency() async -> Bool {
        logger.logI("LatencyRepositoryImpl", "Attempting to update latency data.")
        let pingDatacenterss = getDatacentersPingAndHosts()
        guard pingDatacenterss.count != 0 else {
            logger.logI("LatencyRepositoryImpl", "Datacenter list not ready for latency update.")
            return false
        }
        if locationsManager.getBestLocation() == 0 {
            self.pickBestLocation()
        }
        guard vpnStateRepository.isDisconnected() else {
            self.logger.logI("LatencyRepositoryImpl", "Latency not updated as VPN is not disconnected.")
            return false
        }

        let latencyTask = Task { await self.createLatencyTask(from: pingDatacenterss) }
        setCurrentLatencyTask(latencyTask)
        let pingData = await latencyTask.value
        guard latencyLoadCanCommit(), vpnStateRepository.isDisconnected() else {
            logger.logI("LatencyRepositoryImpl", "Discarded latency update because VPN state changed.")
            return false
        }

        persistPingData(pingData)
        logger.logI("LatencyRepositoryImpl", "Successfully updated latency data.")
        return true
    }

    func checkLocationsValidity() async {
        guard !vpnStateRepository.isConnected() else {
            logger.logI("LatencyRepositoryImpl", "Location validity latency check skipped - VPN is connected.")
            return
        }

        refreshBestLocation()
        await loadLatency()
    }

    func loadStaticIpLatency() async {
        let pingData = await createLatencyTask(from: getStaticPingAndHosts())
        persistPingData(pingData)
        latency.send(self.getPingDataModel())
    }

    func loadCustomConfigLatency() async {
        await getCustomConfigLatency()
        latency.send(self.getPingDataModel())
    }

    private func getPingDataModel() -> [PingDataModel] {
        database.getAllPingData()
    }

    private func getCustomConfigLatency() async {
        let configs = database.getCustomConfigs()
        let serverAddresses = configs.map { $0.serverAddress }

        await withTaskGroup(of: Void.self) { group in
            for address in serverAddresses {
                group.addTask {
                    do {
                        let latency = try await self.getTCPLatency(pingIp: address)
                        self.database.addPingData(pingData: PingDataModel(ip: address, latency: latency))
                    } catch TCPLatencyError.vpnConnected {
                        self.logger.logI("LatencyRepositoryImpl", "getCustomConfigLatency - vpn connected")
                    } catch TCPLatencyError.cancelled {
                        self.logger.logI("LatencyRepositoryImpl", "getCustomConfigLatency - ping was cancelled for \(address)")
                    } catch {
                        self.logger.logE(
                            "LatencyRepositoryImpl",
                            "TCP ping failed for \(address)"
                        )
                    }
                }
            }
        }
    }

    private func getTCPLatency(pingIp: String) async throws -> Int {
#if os(iOS)
        if Task.isCancelled { // Kinda important for unstructured concurrency
            throw TCPLatencyError.cancelled
        }

        if vpnStateRepository.isConnected() {
            throw TCPLatencyError.vpnConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            QNNTcpPing.start(pingIp) { result in
                if Task.isCancelled {
                    continuation.resume(throwing: TCPLatencyError.cancelled)
                    return
                }

                if let minTime = result?.minTime {
                    continuation.resume(returning: Int(minTime))
                } else {
                    continuation.resume(throwing: TCPLatencyError.pingFailed)
                }
            }
        }
#else
        return -1
#endif
    }

    private func findLowestLatencyIP(from pingDataArray: [PingDataModel]) -> String? {
        let pingIps = locationListRepository.currentDatacenterModels
            .filter {
                if (userSessionRepository.sessionModel?.isPremium == false)
                    && $0.isPremiumOnly == true {
                    return false
                } else {
                    return true
                }
            }.compactMap { $0.pingServer?.ip }
        let validPingData = pingDataArray.filter { $0.latency != -1 && pingIps.contains($0.ip) }
        let minLatencyPingData = validPingData.min(by: { $0.latency < $1.latency })
        return minLatencyPingData?.ip
    }

    // MARK: Ping Methods
    private func performPing(ip: String, host: String, pingType: Int32) async -> PingDataModel {
        // Check if task is cancelled before starting
        guard !Task.isCancelled else {
            return PingDataModel(ip: ip, latency: -1)
        }

        let result = await pingManager.ping(ip, hostname: host, pingType: pingType)

        guard !Task.isCancelled else {
            return PingDataModel(ip: ip, latency: -1)
        }
        return PingDataModel(ip: ip, latency: result.success ? Int(result.time) : -1)
    }

    private func performPingTask(ip: String, host: String, pingType: Int32) async -> PingDataModel {
        // Race between ping and timeout using async/await
        await withTaskGroup(of: PingDataModel?.self, returning: PingDataModel.self) { group in
            group.addTask { await self.performPing(ip: ip, host: host, pingType: pingType) }
            group.addTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                return nil
            } // 3 secs timeout

            // Wait for first task to complete
            let result: PingDataModel?
            if let firstResult = await group.next() {
                result = firstResult
            } else {
                result = nil
            }
            group.cancelAll() // Cancel the slower task
            return result ?? PingDataModel(ip: ip, latency: -1)
        }
    }

    private func createLatencyTask(from: [(String, String)]) async -> [PingDataModel] {
        let maxConcurrentTasks = 20
        let pingType = advanceRepository.getPingType()

        return await withTaskGroup(of: PingDataModel.self, returning: [PingDataModel].self) { group in
            var index = 0
            var pingData = [PingDataModel]()

            // Add initial batch of tasks up to maxConcurrentTasks
            for (ip, host) in from.prefix(maxConcurrentTasks) {
                group.addTask { await self.performPingTask(ip: ip, host: host, pingType: pingType) }
                index += 1
            }
            // Process results and add new tasks as they complete
            for await result in group {
                pingData.append(result)
                if index < from.count {
                    let (ip, host) = from[index]
                    group.addTask { await self.performPingTask(ip: ip, host: host, pingType: pingType) }
                    index += 1
                }
            }
            return pingData
        }
    }

    private func persistPingData(_ pingData: [PingDataModel]) {
        pingData.forEach { database.addPingData(pingData: $0) }
    }

    private func beginLatencyLoad() -> Bool {
        latencyLoadLock.lock()
        defer { latencyLoadLock.unlock() }
        guard !isLoadingLatency else { return false }
        isLoadingLatency = true
        wasLatencyLoadCancelled = false
        return true
    }

    private func finishLatencyLoad() {
        latencyLoadLock.lock()
        currentLatencyTask = nil
        isLoadingLatency = false
        wasLatencyLoadCancelled = false
        latencyLoadLock.unlock()
    }

    private func cancelCurrentLatencyLoad() {
        latencyLoadLock.lock()
        guard isLoadingLatency else {
            latencyLoadLock.unlock()
            return
        }
        wasLatencyLoadCancelled = true
        let latencyTask = currentLatencyTask
        latencyLoadLock.unlock()
        latencyTask?.cancel()
    }

    private func setCurrentLatencyTask(_ latencyTask: Task<[PingDataModel], Never>) {
        latencyLoadLock.lock()
        currentLatencyTask = latencyTask
        let shouldCancel = wasLatencyLoadCancelled
        latencyLoadLock.unlock()
        if shouldCancel {
            latencyTask.cancel()
        }
    }

    private func latencyLoadCanCommit() -> Bool {
        latencyLoadLock.lock()
        defer { latencyLoadLock.unlock() }
        return isLoadingLatency && !wasLatencyLoadCancelled
    }

    private func getStaticPingAndHosts() -> [(String, String)] {
        return staticIpRepository.staticIPs.map { ($0.nodes.first?.ip1 ?? "", $0.pingHost) }
    }

    /// Returns ping IP and Host array from database.
    private func getDatacentersPingAndHosts() -> [(String, String)] {
        locationListRepository.currentDatacenterModels
            .compactMap { $0.pingServer }
            .compactMap { ($0.ip, buildHostforPing(from: $0)) }
    }

    private func buildHostforPing(from server: ServerMachineModel) -> String {
        "http://\(server.hostname):6464/latency"
    }

    func refreshBestLocation() {
        let pingData = self.database.getAllPingData()
        self.latency.send(pingData)
        self.pickBestLocation(pingData: pingData)
    }

    func pickBestLocation(pingData: [PingDataModel]) {
        let datacenterList = locationListRepository.currentDatacenterModels
        if let lowestPingIp = findLowestLatencyIP(from: pingData),
           let bestDatacenter = datacenterList.first(where: { $0.pingServer?.ip == lowestPingIp }) {
            self.logger.logI("LatencyRepositoryImpl", "Selected best location based on pingData: \(bestDatacenter.city) \(bestDatacenter.nick)")
            locationsManager.saveBestLocation(with: "\(bestDatacenter.id)")
            return
        }
        self.pickBestLocation()
    }

    /// Picks up Initial best location bast on user's region, status & availability..
    /// Only if we have locations in given region.
    func pickBestLocation() {
        if #available(iOS 16, tvOS 17, *) {
            guard let countryCode = Locale.current.region?.identifier else { return }
            if let regionBasedLocation = self.selectdDatacenterByRegion(countryCode: countryCode) {
                self.logger.logI("LatencyRepositoryImpl", "Selected best location based on region: \(regionBasedLocation)")
                return
            }
        }
        if let timeZoneBasedLocation = self.selectDatacenterByTimeZone() {
            self.logger.logI("LatencyRepositoryImpl", "Selected fallback best location based on time zone: \(timeZoneBasedLocation)")
        }
    }

    /// Select the best datacenter based on the user's region
    private func selectdDatacenterByRegion(countryCode: String) -> String? {
        let locationList = locationListRepository.currentLocationModels
        for location in locationList where location.countryCode == countryCode {
            let availableDatacenters = location.datacenters.filter { datacenter in
                guard !datacenter.servers.isEmpty else { return false }
                if !(self.userSessionRepository.sessionModel?.isPremium ?? false)
                    && datacenter.isPremiumOnly {
                    return false
                }
                return true
            }

            if let selectedDatacenter = availableDatacenters.randomElement() {
                return buildAndSaveBestLocation(datacenter: selectedDatacenter)
            }
        }
        return nil
    }

    /// Select the best datacenter based on the timezon different
    private func selectDatacenterByTimeZone() -> String? {
        let datacenterList = locationListRepository.currentDatacenterModels
        let userTimeZone = TimeZone.current

        let filteredDatacenterList = datacenterList.filter {
            guard !$0.servers.isEmpty else { return false }
            if !(self.userSessionRepository.sessionModel?.isPremium ?? false)
                && $0.isPremiumOnly {
                return false
            }
            guard let timeZone = TimeZone(identifier: $0.tz) else { return false }
            let timeDifference = TimeInterval(abs(timeZone.secondsFromGMT() - userTimeZone.secondsFromGMT()))
            guard timeDifference <= 3600 else { return false }
            return true
        }

        if let selectedDatacenter = filteredDatacenterList.randomElement() {
            return buildAndSaveBestLocation(datacenter: selectedDatacenter)
        }
        return nil
    }

    /// Build and save the best location using the selected Datacenter
    private func buildAndSaveBestLocation(datacenter: DatacenterModel) -> String {
        logger.logI("LatencyRepositoryImpl", "Saving best location: \(datacenter.id), name: \(datacenter.city)")
        locationsManager.saveBestLocation(with: "\(datacenter.id)")
        return datacenter.city
    }
}

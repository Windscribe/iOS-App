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

    let latency = CurrentValueSubject<[PingDataModel], Never>([])
    let latencyUpdatedTrigger = PassthroughSubject<Void, Never>()

    private let favList = CurrentValueSubject<[FavouriteModel], Never>([])
    private var observingBestLocation = false
    private var cancellables = Set<AnyCancellable>()
    private var startTimeStamp = Date()
    private var hasPassedInitialTimer = false
    private var isLoadingLatency = false

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

        let queue = DispatchQueue(label: "debounce.queue")

        locationListRepository.datacenterListSubject
            .debounce(for: .milliseconds(500), scheduler: queue)
            .first(where: { !$0.isEmpty })
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                   await self.loadLatency()
                }
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
        // Guard: if already loading, skip to prevent duplicate simultaneous pings
        guard !isLoadingLatency else {
            logger.logI("LatencyRepositoryImpl", "Latency update already in progress, skipping duplicate request.")
            return
        }

        isLoadingLatency = true
        defer { isLoadingLatency = false }

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

        guard !vpnStateRepository.isConnected() else {
            logger.logI("LatencyRepositoryImpl", "Latency update skipped - VPN is connected.")
            return
        }

        await loadAllDatacentersLatency()
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

        do {
            try await createLatencyTask(from: nearbyDatacenterServers.map { ($0.ip, buildHostforPing(from: $0)) })
            refreshBestLocation()
            logger.logI("LatencyRepositoryImpl", "Quick latency complete. Best location updated with \(nearbyDatacenterServers.count) datacenters.")
        } catch {
            logger.logE("LatencyRepositoryImpl", "Quick latency failed: \(error)")
            throw error
        }
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

    private func loadAllDatacentersLatency() async {
        logger.logI("LatencyRepositoryImpl", "Attempting to update latency data.")
        let pingDatacenterss = getDatacentersPingAndHosts()
        guard pingDatacenterss.count != 0 else {
            logger.logI("LatencyRepositoryImpl", "Datacenter list not ready for latency update.")
            return
        }
        if locationsManager.getBestLocation() == 0 {
            self.pickBestLocation()
        }
        guard !vpnStateRepository.isConnected() else {
            self.logger.logI("LatencyRepositoryImpl", "Latency not updated as vpn is connected")
            return
        }
        do {
            try await createLatencyTask(from: pingDatacenterss)
            self.logger.logI("LatencyRepositoryImpl", "Successfully updated latency data.")
        } catch {
            self.logger.logE("LatencyRepositoryImpl", "Failure to update latency data.")
        }
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
        try? await createLatencyTask(from: getStaticPingAndHosts())
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
    private func performPing(ip: String, host: String, pingType: Int32) async {
        // Check if task is cancelled before starting
        guard !Task.isCancelled else {
            self.database.addPingData(pingData: PingDataModel(ip: ip, latency: -1))
            return
        }

        let result = await pingManager.ping(ip, hostname: host, pingType: pingType)

        guard !Task.isCancelled else {
            self.database.addPingData(pingData: PingDataModel(ip: ip, latency: -1))
            return
        }
        self.database.addPingData(pingData: PingDataModel(ip: ip, latency: result.success ? Int(result.time) : -1))
    }

    private func performPingTask(ip: String, host: String, pingType: Int32) async {
        // Race between ping and timeout using async/await
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.performPing(ip: ip, host: host, pingType: pingType) }
            group.addTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            } // 3 secs timeout

            // Wait for first task to complete
            await group.next()
            group.cancelAll() // Cancel the slower task
        }
    }

    private func createLatencyTask(from: [(String, String)]) async throws {
        let maxConcurrentTasks = 20
        let pingType = advanceRepository.getPingType()

        await withTaskGroup(of: Void.self) { group in
            var index = 0

            // Add initial batch of tasks up to maxConcurrentTasks
            for (ip, host) in from.prefix(maxConcurrentTasks) {
                group.addTask { await self.performPingTask(ip: ip, host: host, pingType: pingType) }
                index += 1
            }
            // Process results and add new tasks as they complete
            for await _ in group where index < from.count {
                let (ip, host) = from[index]
                group.addTask { await self.performPingTask(ip: ip, host: host, pingType: pingType) }
                index += 1
            }
        }
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

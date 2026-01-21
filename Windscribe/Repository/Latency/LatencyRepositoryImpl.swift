//
//  LatencyRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Realm
import Combine
import Swinject
import RealmSwift

enum TCPLatencyError: Error {
    case cancelled
    case vpnConnected
    case pingFailed
    case notIOS
}

class LatencyRepositoryImpl: LatencyRepository {
    private let pingManager: LocalPingManager
    private let database: LocalDatabase
    private let logger: FileLogger
    private let vpnStateRepository: VPNStateRepository
    private let locationsManager: LocationsManager
    private let preferences: Preferences
    private let advanceRepository: AdvanceRepository
    private let serverRepository: ServerRepository
    private let userSessionRepository: UserSessionRepository
    private let staticIpRepository: StaticIpRepository

    let latency = CurrentValueSubject<[PingDataModel], Never>([])
    private let favList = CurrentValueSubject<[FavouriteModel], Never>([])
    private var observingBestLocation = false
    private var cancellables = Set<AnyCancellable>()
    private var startTimeStamp = Date()
    private var hasPassedInitialTimer = false

    init(pingManager: LocalPingManager,
         database: LocalDatabase,
         vpnStateRepository: VPNStateRepository,
         logger: FileLogger,
         locationsManager: LocationsManager,
         preferences: Preferences,
         advanceRepository: AdvanceRepository,
         serverRepository: ServerRepository,
         userSessionRepository: UserSessionRepository,
         staticIpRepository: StaticIpRepository) {
        self.pingManager = pingManager
        self.database = database
        self.vpnStateRepository = vpnStateRepository
        self.logger = logger
        self.locationsManager = locationsManager
        self.preferences = preferences
        self.advanceRepository = advanceRepository
        self.serverRepository = serverRepository
        self.userSessionRepository = userSessionRepository
        self.staticIpRepository = staticIpRepository

        latency.send(self.database.getAllPingData().map { PingDataModel(from: $0) })
        observeFavouriteList()

        refreshBestLocation()
    }

    private func observeFavouriteList() {
        database.getFavouriteListPublisher()
            .sink { favList in
                self.favList.send(favList.map { $0.getModel() })
            }
            .store(in: &self.cancellables)
    }

    /// Returns latency data for ip.
    func getPingData(ip: String) -> PingDataModel? {
        let value = latency.value
        return value.first { $0.ip == ip }
    }

    func loadLatency() async {
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
        await loadAllServerLatency()
        refreshBestLocation()
    }

    private func loadAllServerLatency() async {
        logger.logI("LatencyRepositoryImpl", "Attempting to update latency data.")
        let pingServers = getServerPingAndHosts()
        guard pingServers.count != 0 else {
            logger.logI("LatencyRepositoryImpl", "Server list not ready for latency update.")
            return
        }
        if locationsManager.getBestLocation() == "0" {
            self.pickBestLocation()
        }
        guard !vpnStateRepository.isConnected() else {
            self.logger.logI("LatencyRepositoryImpl", "Latency not updated as vpn is connected")
            return
        }
        do {
            try await createLatencyTask(from: pingServers)
            self.logger.logI("LatencyRepositoryImpl", "Successfully updated latency data.")
        } catch {
            self.logger.logE("LatencyRepositoryImpl", "Failure to update latency data.")
        }
    }

    func checkLocationsValidity() async {
        refreshBestLocation()
        if !vpnStateRepository.isConnected() {
            await loadLatency()
        }
    }

    func loadStreamingServerLatency() async {
        let streamingServersToPing = database.getServers()?
            .filter { $0.locType == "streaming" }
            .compactMap { region in Array(region.groups) }
            .reduce([], +)
            .map { city in (city.pingIp, city.pingHost) }
        try? await createLatencyTask(from: streamingServersToPing ?? [])
        latency.send(self.getPingDataModel())
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
        database.getAllPingData().map { PingDataModel(from: $0)}
    }

    private func getCustomConfigLatency() async {
        let configs = database.getCustomConfigs()
        let serverAddresses = configs.map { $0.serverAddress }

        await withTaskGroup(of: Void.self) { group in
            for address in serverAddresses {
                group.addTask {
                    do {
                        let latency = try await self.getTCPLatency(pingIp: address)

                        let pingData = PingData(
                            ip: address,
                            latency: latency
                        )

                        self.database.addPingData(pingData: pingData)

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
        let pingIps = serverRepository.currentServerModels
            .compactMap { region in Array(region.groups)}
            .reduce([], +)
            .filter {
                if (userSessionRepository.sessionModel?.isPremium == false)
                    && $0.premiumOnly == true {
                    return false
                } else {
                    return true
                }
            }.map { $0.pingIp }
        let validPingData = pingDataArray.filter { $0.latency != -1 && pingIps.contains($0.ip) }
        let minLatencyPingData = validPingData.min(by: { $0.latency < $1.latency })
        return minLatencyPingData?.ip
    }

    // MARK: Ping Methods
    private func performPing(ip: String, host: String, pingType: Int32) async {
        var result = await withCheckedContinuation { continuation in
            self.pingManager.ping(ip, hostname: host, pingType: pingType) { _, _, time, success in
                continuation.resume(returning: (time: time, success: success))
            }
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        if Task.isCancelled {
            result.success = false
        }
        self.database.addPingData(pingData: PingData(ip: ip, latency: result.success ? Int(result.time) : -1))
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
            for await _ in group {
                // Add next task if there are more
                if index < from.count {
                    let (ip, host) = from[index]
                    group.addTask { await self.performPingTask(ip: ip, host: host, pingType: pingType) }
                    index += 1
                }
            }
        }
    }

    private func getStaticPingAndHosts() -> [(String, String)] {
        return staticIpRepository.staticIPs.map { ($0.nodes.first?.ip1 ?? "", $0.pingHost) }
    }

    /// Returns ping IP and Host array from database.
    private func getServerPingAndHosts() -> [(String, String)] {
        return serverRepository.currentServerModels
            .compactMap { region in Array(region.groups) }
            .reduce([], +)
            .map { city in (city.pingIp, city.pingHost) }
    }

    func refreshBestLocation() {
        let pingData = self.database.getAllPingData().map { PingDataModel.init(from: $0) }
        self.latency.send(pingData)
        self.pickBestLocation(pingData: pingData)
    }

    func pickBestLocation(pingData: [PingDataModel]) {
        let servers = serverRepository.currentServerModels
        var locationFound = false
        if let lowestPingIp = findLowestLatencyIP(from: pingData) {
            outerLoop: for server in servers {
                for group in server.groups where group.pingIp == lowestPingIp {
                    self.logger.logI("LatencyRepositoryImpl", "Selected best location based on pingData: \(group.countryCode ?? "??") \(group.city) \(group.nick)")
                    locationsManager.saveBestLocation(with: "\(group.id)")
                    locationFound = true
                    break outerLoop
                }
            }
        }
        if !locationFound {
            self.pickBestLocation()
        }
    }

    /// Picks up Initial best location bast on user's region, status & availability..
    /// Only if we have servers in given region.
    func pickBestLocation() {
        DispatchQueue.main.async {
            let servers = self.serverRepository.currentServerModels
            if #available(iOS 16, tvOS 17, *) {
                guard let countryCode = Locale.current.region?.identifier else { return }
                if let regionBasedLocation = self.selectServerByRegion(servers: servers, countryCode: countryCode) {
                    self.logger.logI("LatencyRepositoryImpl", "Selected best location based on region: \(regionBasedLocation)")
                    return
                }
            }
            if let timeZoneBasedLocation = self.selectServerByTimeZone(servers: servers) {
                self.logger.logI("LatencyRepositoryImpl", "Selected fallback best location based on time zone: \(timeZoneBasedLocation)")
            }
        }
    }

    /// Select the best server based on the user's region
    private func selectServerByRegion(servers: [ServerModel], countryCode: String) -> String? {
        for server in servers where server.countryCode == countryCode {
            let availableGroups = server.groups.filter { group in
                guard !group.nodes.isEmpty else { return false }
                if !(self.userSessionRepository.sessionModel?.isPremium ?? false)
                    && server.premiumOnly {
                    return false
                }
                return true
            }

            if let selectedGroup = availableGroups.randomElement() {
                return buildAndSaveBestLocation(group: selectedGroup)
            }
        }
        return nil
    }

    /// Select the best server based on the timezon different
    private func selectServerByTimeZone(servers: [ServerModel]) -> String? {
        let userTimeZone = TimeZone.current
        var bestFallbackGroup: GroupModel?
        for server in servers {
            guard let serverTimeZone = TimeZone(identifier: server.timezone) else { continue }

            let timeDifference = TimeInterval(abs(serverTimeZone.secondsFromGMT() - userTimeZone.secondsFromGMT()))
            // Anything equal to 1 hour or less difference is fine.
            if timeDifference <= 3600 {
                let availableGroups = server.groups.filter { group in
                    guard !group.nodes.isEmpty else { return false }
                    if !(self.userSessionRepository.sessionModel?.isPremium ?? false)
                        && server.premiumOnly {
                        return false
                    }
                    return true
                }
                if let selectedGroup = availableGroups.randomElement() {
                    bestFallbackGroup = selectedGroup
                }
            }
        }
        if let bestGroup = bestFallbackGroup {
            return buildAndSaveBestLocation(group: bestGroup)
        }
        return nil
    }

    /// Build and save the best location using the selected server, group, and node
    private func buildAndSaveBestLocation(group: GroupModel) -> String {
        logger.logI("LatencyRepositoryImpl", "Saving best location: \(group.id), name: \(group.city)  country:\(group.countryCode ?? "--")")
        locationsManager.saveBestLocation(with: "\(group.id)")
        return group.city
    }
}

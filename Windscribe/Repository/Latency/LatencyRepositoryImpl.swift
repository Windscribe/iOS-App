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
import RxSwift
import Swinject
import RealmSwift
import Combine

class LatencyRepositoryImpl: LatencyRepository {
    private let pingManager: WSNetPingManager
    private let database: LocalDatabase
    private let logger: FileLogger
    private let vpnManager: VPNManager
    private let locationsManager: LocationsManager
    private let preferences: Preferences
    private let advanceRepository: AdvanceRepository
    private var sessionManager: SessionManager {
        return Assembler.resolve(SessionManager.self)
    }

    private let disposeBag = DisposeBag()
    let latency: BehaviorSubject<[PingData]> = BehaviorSubject(value: [])
    private let favList: BehaviorSubject<[Favourite]> = BehaviorSubject(value: [])
    private var observingBestLocation = false
    private var cancellables = Set<AnyCancellable>()

    init(pingManager: WSNetPingManager,
         database: LocalDatabase,
         vpnManager: VPNManager,
         logger: FileLogger,
         locationsManager: LocationsManager,
         preferences: Preferences,
         advanceRepository: AdvanceRepository) {
        self.pingManager = pingManager
        self.database = database
        self.vpnManager = vpnManager
        self.logger = logger
        self.locationsManager = locationsManager
        self.preferences = preferences
        self.advanceRepository = advanceRepository
        latency.onNext(self.database.getAllPingData())
        observeFavouriteList()
    }

    private func observeFavouriteList() {
        database.getFavouriteListObservable().subscribe(onNext: { favList in
            self.favList.onNext(favList)
        }, onError: { _ in
        }).disposed(by: disposeBag)
    }

    /// Returns latency data for ip.
    func getPingData(ip: String) -> PingData? {
        let value = try? latency.value()
        return value?.first { !$0.isInvalidated && $0.ip == ip }
    }

    func loadLatency() {
        loadAllServerLatency()
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onCompleted: {})
            .disposed(by: disposeBag)
    }

    func loadAllServerLatency() -> Completable {
        logger.logE("LatencyRepositoryImpl", "Attempting to update latency data.")
        let pingServers = getServerPingAndHosts()
        if pingServers.count == 0 {
            logger.logE("LatencyRepositoryImpl", "Server list not ready for latency update.")
            return Completable.empty()
        }
        if locationsManager.getBestLocation() == "0" {
            self.pickBestLocation()
        }
        if vpnManager.isConnected() {
            self.logger.logE("LatencyRepositoryImpl", "Latency not updated as vpn is connected")
            return Completable.empty()
        }
        let latencySingles = createLatencyTask(from: pingServers)
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .timeout(.seconds(20), other: Single<[PingData]>.error(RxError.timeout), scheduler: MainScheduler.instance)
        latencySingles.subscribe(
            onSuccess: { _ in
                self.logger.logI("LatencyRepositoryImpl", "Successfully updated latency data.")
                self.refreshBestLocation()
            },
            onFailure: { _ in
                self.logger.logE("LatencyRepositoryImpl", "Failure to update latency data.")
                self.refreshBestLocation()
            })
        .disposed(by: self.disposeBag)

        return latencySingles.asCompletable()
    }

    func loadStreamingServerLatency() -> Completable {
        let streamingServersToPing = database.getServers()?
            .filter { $0.locType == "streaming" }
            .compactMap { region in Array(region.groups) }
            .reduce([], +)
            .map { city in (city.pingIp, city.pingHost) }
        return createLatencyTask(from: streamingServersToPing ?? [])
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .do(onSuccess: { _ in self.latency.onNext(self.database.getAllPingData()) })
            .asCompletable()
    }

    func loadStaticIpLatency() -> Single<[PingData]> {
        createLatencyTask(from: getStaticPingAndHosts())
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { _ in
                DispatchQueue.main.async {
                    self.latency.onNext(self.database.getAllPingData())
                }
            })
    }

    func loadCustomConfigLatency() -> Completable {
        getCustomConfigLatency()
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { _ in
                let pingData = self.database.getAllPingData()
                self.latency.onNext(pingData)
            }).asCompletable()
    }

    private func getCustomConfigLatency() -> Single<[PingData]> {
        return Single<[PingData]>.create { completion in
            autoreleasepool {
                DispatchQueue.global().async {
                let threadSafeConfigs = Array(self.database.getCustomConfigs()).map { ThreadSafeReference(to: $0) }
                var tasks: [Single<PingData>] = []
                if let realm = try? Realm() {
                    for ref in threadSafeConfigs {
                        let task = Single<PingData>.create { innerCompletion in
                            autoreleasepool {
                                    if let config = realm.resolve(ref) {
                                        let pingData = PingData(ip: config.serverAddress, latency: -1)
                                        self.getTCPLatency(pingIp: config.serverAddress) { minTime in
                                            if minTime != -1 {
                                                pingData.latency = minTime
                                                self.database.addPingData(pingData: pingData)
                                            }
                                            innerCompletion(.success(pingData))
                                        }
                                    } else {
                                        innerCompletion(.failure(Realm.Error(.fail)))
                                    }
                                return Disposables.create()
                            }
                        }
                        tasks.append(task)
                    }
                    Observable.zip(tasks.map { $0.asObservable() })
                        .asSingle()
                        .subscribe(onSuccess: { result in
                            completion(.success(result))
                        }, onFailure: { error in
                            completion(.failure(error))
                        })
                        .disposed(by: self.disposeBag)
                }
                }
            }
            return Disposables.create()
        }
    }

    private func getTCPLatency(pingIp: String, completion: @escaping (_ minTime: Int) -> Void) {
#if os(iOS)
        if vpnManager.isConnected() {
            completion(-1)
        } else {
            _ = DispatchQueue(label: "Ping", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil).sync {
                QNNTcpPing.start(pingIp) { result in
                    if let minTime = result?.minTime {
                        completion(Int(minTime))
                    } else {
                        self.logger.logE("LatencyRepositoryImpl", "Error when performing TCP ping to given node. \(pingIp)")
                        completion(-1)
                    }
                }
            }
        }
#endif
    }

    private func findLowestLatencyIP(from pingDataArray: [PingData]) -> String? {
        let pingIps = database.getServers()?
            .compactMap { region in Array(region.groups)}
            .reduce([], +)
            .filter {
                if sessionManager.session?.isPremium == false && $0.premiumOnly == true {
                    return false
                } else {
                    return true
                }
            }.map { $0.pingIp } ?? []
        let validPingData = pingDataArray.filter { $0.latency != -1 && pingIps.contains($0.ip) }
        let minLatencyPingData = validPingData.min(by: { $0.latency < $1.latency })
        return minLatencyPingData?.ip
    }

    private func createLatencyTask(from: [(String, String)]) -> Single<[PingData]> {
        let maxConcurrentTasks = 20
        return Single.create { single in
            let pingPublishers = from.map { (ip, host) in
                Future<PingData, Never> { promise in
                    var hasDeliveredResult = false
                    let timeoutCancellable = Just(PingData(ip: ip, latency: -1))
                        .delay(for: .seconds(3), scheduler: DispatchQueue.global(qos: .userInitiated))
                        .sink {
                            if !hasDeliveredResult {
                                hasDeliveredResult = true
                                promise(.success($0))
                            }
                        }

                    self.pingManager.ping(ip, hostname: host,
                                          pingType: self.advanceRepository.getPingType()) { ip, _, time, success in
                        if !hasDeliveredResult {
                            hasDeliveredResult = true
                            timeoutCancellable.cancel() // Cancel timeout if we get a response
                            let pingData = PingData(ip: ip, latency: success ? Int(time) : -1)
                            if success {
                                self.database.addPingData(pingData: pingData)
                            }
                            promise(.success(pingData))
                        }
                    }
                }
            }
            let cancellable = pingPublishers
                .publisher
                .flatMap(maxPublishers: .max(maxConcurrentTasks)) { $0 }
                .collect()
                .sink(receiveCompletion: { _ in }, receiveValue: { results in
                    single(.success(results))
                })
            cancellable.store(in: &self.cancellables)
            return Disposables.create {
                cancellable.cancel()
            }
        }
    }

    private func getStaticPingAndHosts() -> [(String, String)] {
        return database.getStaticIPs()?.compactMap { $0 }
            .map { city in (city.nodes.first?.ip ?? "", city.pingHost) } ?? []
    }

    /// Returns ping IP and Host array from database.
    private func getServerPingAndHosts() -> [(String, String)] {
        return database.getServers()?
            .compactMap { region in Array(region.groups) }
            .reduce([], +)
            .map { city in (city.pingIp, city.pingHost) } ?? []
    }

    func refreshBestLocation() {
        let pingData = self.database.getAllPingData()
        self.latency.onNext(pingData)
        self.pickBestLocation(pingData: pingData)
    }

    func pickBestLocation(pingData: [PingData]) {
        let servers = database.getServers()
        if let lowestPingIp = findLowestLatencyIP(from: pingData) {
            outerLoop: for server in servers ?? [] {
                for group in server.groups where group.pingIp == lowestPingIp {
                    locationsManager.saveBestLocation(with: "\(group.id)")
                    break outerLoop
                }
            }
        } else {
            return
        }
    }

    /// Picks up Initial best location bast on user's region, status & availability..
    /// Only if we have servers in given region.
    func pickBestLocation() {
        DispatchQueue.main.async {
            let servers = self.database.getServers() ?? []
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
    private func selectServerByRegion(servers: [Server], countryCode: String) -> String? {
        for server in servers where server.countryCode == countryCode {
            let availableGroups = server.groups.filter { group in
                guard !group.nodes.isEmpty else { return false }
                if !(self.sessionManager.session?.isPremium ?? false) && server.premiumOnly {
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
    private func selectServerByTimeZone(servers: [Server]) -> String? {
        let userTimeZone = TimeZone.current
        var bestFallbackGroup: Group?
        for server in servers {
            guard let serverTimeZone = TimeZone(identifier: server.timezone) else { continue }

            let timeDifference = TimeInterval(abs(serverTimeZone.secondsFromGMT() - userTimeZone.secondsFromGMT()))
            // Anything equal to 1 hour or less difference is fine.
            if timeDifference <= 3600 {
                let availableGroups = server.groups.filter { group in
                    guard !group.nodes.isEmpty else { return false }
                    if !(self.sessionManager.session?.isPremium ?? false) && server.premiumOnly {
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
    private func buildAndSaveBestLocation(group: Group) -> String {
        logger.logI("LatencyRepositoryImpl", "Saving best location: \(group.id)")
        locationsManager.saveBestLocation(with: "\(group.id)")
        return group.city
    }
}

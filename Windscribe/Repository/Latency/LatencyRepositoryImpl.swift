//
//  LatencyRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Realm
import RxRealm
import Swinject
import NetworkExtension
class LatencyRepositoryImpl: LatencyRepository {
    private let pingManager: WSNetPingManager
    private let database: LocalDatabase
    private let logger: FileLogger
    private let vpnManager: VPNManager
    private var sessionManager: SessionManagerV2 {
        return Assembler.resolve(SessionManagerV2.self)
    }
    private let disposeBag = DisposeBag()
    let latency: BehaviorSubject<[PingData]> = BehaviorSubject(value: [])
    let bestLocation: BehaviorSubject <BestLocation?> = BehaviorSubject(value: nil)
    private let favNodes: BehaviorSubject<[FavNode]> = BehaviorSubject(value: [])
    private var observingBestLocation = false

    init(pingManager: WSNetPingManager, database: LocalDatabase, vpnManager: VPNManager, logger: FileLogger) {
        self.pingManager = pingManager
        self.database = database
        self.vpnManager = vpnManager
        self.logger = logger
        self.latency.onNext(self.database.getAllPingData())
        observeBestLocation()
        observeFavNodes()
    }

    private func observeBestLocation() {
        observingBestLocation = true
        database.getBestLocation().subscribe(onNext: { location in
            self.logger.logD(self, "Updated best location to \(location?.cityName ?? "")")
            self.bestLocation.onNext(location)
        }, onError: { _ in
            self.bestLocation.onNext(nil)
        }, onCompleted: {
            self.observingBestLocation = false
        }).disposed(by: disposeBag)
    }

    private func observeFavNodes() {
        database.getFavNode().subscribe(onNext: { favNodes in
            self.favNodes.onNext(favNodes)
        }, onError: { _ in
        }).disposed(by: disposeBag)
    }

    /// Returns latency data for ip.
    func getPingData(ip: String) -> PingData? {
        let value = try? latency.value()
        return value?.first { !$0.isInvalidated  && $0.ip == ip }
    }

    func loadLatency() {
        loadAllServerLatency()
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onCompleted: {})
            .disposed(by: self.disposeBag)
    }

    func loadAllServerLatency() -> Completable {
        self.logger.logE(self, "Attempting to update latency data.")
        let pingServers = self.getServerPingAndHosts()
        if pingServers.count == 0 {
            self.logger.logE(self, "Server list not ready for latency update.")
            return Completable.empty()
        }
        let latencySingles =  self.createLatencyTask(from: pingServers)
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .timeout(.seconds(20), other: Single<[PingData]>.error(RxError.timeout), scheduler: MainScheduler.instance)

        latencySingles.subscribe(
            onFailure: { _ in
                self.logger.logE(self, "Failure to update latency data.")
                let pingData = self.database.getAllPingData()
                self.latency.onNext(pingData)
                self.pickBestLocation(pingData: pingData)
            }
        )
        .disposed(by: self.disposeBag)

        return latencySingles.do(onSuccess: { _ in
            self.logger.logE(self, "Successfully updated latency data.")
            let pingData = self.database.getAllPingData()
            self.latency.onNext(pingData)
            self.pickBestLocation(pingData: pingData)
        }).asCompletable()
    }

    func loadFavouriteLatency() -> Completable {
        let favourites = try? favNodes.value().map { p in ( p.pingIp, p.pingHost)}
        return self.createLatencyTask(from: favourites ?? [])
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .do(onSuccess: { _ in self.latency.onNext(self.database.getAllPingData())})
            .asCompletable()
    }

    func loadStreamingServerLatency() -> Completable {
        let streamingServersToPing = database.getServers()?
            .filter { $0.locType == "streaming"}
            .compactMap { region in region.groups.toArray()}
            .reduce([], +)
            .map { city in (city.pingIp, city.pingHost)}
        return self.createLatencyTask(from: streamingServersToPing ?? [])
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .do(onSuccess: { _ in  self.latency.onNext(self.database.getAllPingData())})
            .asCompletable()
    }

    func loadStaticIpLatency() -> Single<[PingData]> {
        self.createLatencyTask(from: self.getStaticPingAndHosts())
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .do(onSuccess: { _ in  self.latency.onNext(self.database.getAllPingData()) })
    }

    func loadCustomConfigLatency() -> Completable {
        getCustomConfigLatency()
            .observe(on: MainScheduler.instance)
            .subscribe(on: MainScheduler.instance)
            .do(onSuccess: { _ in
                let pingData = self.database.getAllPingData()
                self.latency.onNext(pingData)
            }).asCompletable()
    }

    func getCustomConfigLatency() -> Single<[PingData]> {
        let tasks = database.getCustomConfigs().map { config in
            return Single<PingData>.create { completion in
                let pingData = PingData(ip: config.serverAddress, latency: -1)
                self.getTCPLatency(pingIp: config.serverAddress) { minTime in
                    if minTime != -1 {
                        pingData.latency = minTime
                        self.database.addPingData(pingData: pingData).disposed(by: self.disposeBag)
                    }
                    completion(.success(pingData))
                }
                return Disposables.create()
            }
        }.map { single in single.asObservable() }
        return Observable.zip(tasks).asSingle()
    }

    private func getTCPLatency(pingIp: String, completion: @escaping (_ minTime: Int) -> Void) {
        #if os(iOS)
        if vpnManager.isConnected() {
            completion(-1)
        } else {
            _ = DispatchQueue(label: "Ping", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil).sync {
                QNNTcpPing.start(pingIp) { (result) in
                    if let minTime = result?.minTime {
                        completion(Int(minTime))
                    } else {
                        self.logger.logE(self, "Error when performing TCP ping to given node. \(pingIp)")
                        completion(-1)
                    }
                }
            }
        }
        #endif
    }

    private func findLowestLatencyIP(from pingDataArray: [PingData]) -> String? {
        let pingIps = database.getServers()?
        .compactMap { region in region.groups.toArray()}
        .reduce([], +)
        .filter {
            if sessionManager.session?.isPremium == false && $0.premiumOnly == true {
                return false
            } else {
                return true
            }
        }.map {$0.pingIp} ?? []
        let validPingData = pingDataArray.filter { $0.latency != -1 && pingIps.contains($0.ip)}
        let minLatencyPingData = validPingData.min(by: { $0.latency < $1.latency })
        return minLatencyPingData?.ip
    }

    /// Returns single task built from list of ip and hosts.
    private func createLatencyTask(from: [(String, String)]) -> Single<[PingData]> {
        let tasks = from.map { ip, host in
            return Single<PingData>.create { completion in
                self.pingManager.ping(ip, hostname: host, pingType: 0) { ip, _, time, success in
                    let pingData = PingData(ip: ip, latency: -1)
                    if success {
                        pingData.latency = Int(time)
                        self.database.addPingData(pingData: pingData).disposed(by: self.disposeBag)
                    }
                    completion(.success(pingData))
                }
                return Disposables.create()
            }
        }.map { single in single.asObservable() }
        return Observable.zip(tasks).asSingle()
    }

    private func getStaticPingAndHosts() -> [(String, String)] {
        return database.getStaticIPs()?.compactMap {$0}
            .map { city in return (city.nodes.first?.ip ?? "", city.pingHost)} ?? []
    }

    /// Returns ping IP and Host array from database.
    private func getServerPingAndHosts() -> [(String, String)] {
        return database.getServers()?
            .compactMap { region in region.groups.toArray()}
            .reduce([], +)
            .map { city in return (city.pingIp, city.pingHost) } ?? []
    }

    func pickBestLocation(pingData: [PingData]) {
        let servers = database.getServers()
        if let lowestPingIp = findLowestLatencyIP(from: pingData) {
        outerLoop: for server in servers ?? [] {
            for group in server.groups {
                if group.pingIp == lowestPingIp,
                   let bestNode = group.bestNode?.getNodeModel(),
                   let serverModel = server.getServerModel() {
                    let bestLocation = BestLocation(node: bestNode, group: group.getGroupModel(), server: serverModel)
                    database.saveBestLocation(location: bestLocation).disposed(by: disposeBag)
                    break outerLoop
                }
            }
        }
        } else {
            return
        }
        let lastBestLocation = try? bestLocation.value()
        if !observingBestLocation || lastBestLocation == nil {
            delay(2) {
                self.observeBestLocation()
            }
        }
    }

    /// Picks up Initial best location bast on user's region, status & availability..
    /// Only if we have servers in given region.
    func pickBestLocation(servers: [Server]) {
        if #available(iOS 16, tvOS 17, *) {
            guard let countryCode = Locale.current.region?.identifier else { return }
            logger.logD(self, "User region: \(countryCode)")
            if let regionBasedLocation = selectServerByRegion(servers: servers, countryCode: countryCode) {
                logger.logD(self, "Selected best location based on region: \(regionBasedLocation.cityName)")
                return
            }
        }
        if let timeZoneBasedLocation = selectServerByTimeZone(servers: servers) {
            logger.logD(self, "Selected fallback best location based on time zone: \(timeZoneBasedLocation.cityName)")
        }
    }

    /// Select the best server based on the user's region
    private func selectServerByRegion(servers: [Server], countryCode: String) -> BestLocation? {
        for server in servers where server.countryCode == countryCode {
            let availableGroups = server.groups.filter { group in
                guard !group.nodes.isEmpty else { return false }
                if !(self.sessionManager.session?.isUserPro ?? false) && server.premiumOnly {
                    return false
                }
                return true
            }

            if let selectedGroup = availableGroups.randomElement(),
               let selectedNode = selectedGroup.nodes.randomElement() {
                return buildAndSaveBestLocation(server: server, group: selectedGroup, node: selectedNode)
            }
        }
        return nil
    }

    /// Select the best server based on the timezon different
    private func selectServerByTimeZone(servers: [Server]) -> BestLocation? {
        let userTimeZone = TimeZone.current
        var bestFallbackServer: Server?
        var bestFallbackGroup: Group?
        var bestFallbackNode: Node?
        for server in servers {
            guard let serverTimeZone = TimeZone(identifier: server.timezone) else { continue }

            let timeDifference = TimeInterval(abs(serverTimeZone.secondsFromGMT() - userTimeZone.secondsFromGMT()))
            // Anything equal to 1 hour or less difference is fine.
            if timeDifference <= 3600 {
                let availableGroups = server.groups.filter { group in
                    guard !group.nodes.isEmpty else { return false }
                    if !(self.sessionManager.session?.isUserPro ?? false) && server.premiumOnly {
                        return false
                    }
                    return true
                }
                if let selectedGroup = availableGroups.randomElement(),
                   let selectedNode = selectedGroup.nodes.randomElement() {
                    bestFallbackServer = server
                    bestFallbackGroup = selectedGroup
                    bestFallbackNode = selectedNode
                }
            }
        }
        if let bestServer = bestFallbackServer,
           let bestGroup = bestFallbackGroup,
           let bestNode = bestFallbackNode {
            return buildAndSaveBestLocation(server: bestServer, group: bestGroup, node: bestNode)
        }
        return nil
    }

    /// Build and save the best location using the selected server, group, and node
    private func buildAndSaveBestLocation(server: Server, group: Group, node: Node) -> BestLocation {
        let updatedBestLocation = BestLocation(
            node: node.getNodeModel(),
            group: group.getGroupModel(),
            server: server.getServerModel()!
        )
        self.database.saveBestLocation(location: updatedBestLocation)
            .disposed(by: disposeBag)
        let lastBestLocation = try? bestLocation.value()
        if !observingBestLocation || lastBestLocation == nil {
            delay(2) {
                self.observeBestLocation()
            }
        }
        return updatedBestLocation
    }
}

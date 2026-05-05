//
//  SnapshotComparisonTests.swift
//  WindscribeTests
//
//  Created for the Realm → GRDB migration parity harness.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import XCTest
import Foundation
import GRDB
@testable import Windscribe

/// Captures a deterministic JSON snapshot of every getter on LocalDatabase and compares
/// it to baseline_snapshot.json. Regenerate the baseline by deleting the file and re-running.
final class SnapshotComparisonTests: XCTestCase {

    /// Path to the committed golden file in the source tree. Resolved relative to this
    /// source file via `#filePath` so the test works on any machine whose checkout path
    /// differs from the original author's (notably CI runners). Kept as a source-tree
    /// file (not a Bundle resource) so it shows up as a reviewable diff in PRs.
    private static var baselineFileURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/baseline_snapshot.json")
    }

    // MARK: - Main regression test

    func testRealmBackedSnapshotMatchesBaseline() throws {
        let db = TestLocalDatabaseImpl(logger: MockLogger(), preferences: MockPreferences())
        RealisticDataFixture.seedRealisticData(db: db)

        let snapshot = try SnapshotCapturer.capture(db: db)

        let fm = FileManager.default
        if !fm.fileExists(atPath: Self.baselineFileURL.path) {
            // First run: write the snapshot as the new baseline, then fail with a clear message.
            try fm.createDirectory(at: Self.baselineFileURL.deletingLastPathComponent(),
                                   withIntermediateDirectories: true)
            try snapshot.write(to: Self.baselineFileURL)
            XCTFail("""
                No baseline existed. Wrote new baseline to:
                  \(Self.baselineFileURL.path)
                Review the file, commit it, and re-run the test.
                """)
            return
        }

        let baseline = try Data(contentsOf: Self.baselineFileURL)
        if snapshot != baseline {
            // Write the live snapshot alongside the baseline for easy diffing.
            let liveURL = Self.baselineFileURL
                .deletingLastPathComponent()
                .appendingPathComponent("live_snapshot.json")
            try snapshot.write(to: liveURL)
            XCTFail("""
                Snapshot diverged from baseline.
                Live snapshot: \(liveURL.path)
                Baseline:      \(Self.baselineFileURL.path)
                Run: diff \(Self.baselineFileURL.path) \(liveURL.path)
                If the change is intentional, delete baseline_snapshot.json and re-run to regenerate.
                """)
        }
    }

    func testGRDBBackedSnapshotMatchesBaseline() throws {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        let db: LocalDatabase = GRDBLocalDatabaseImpl(
            logger: MockLogger(),
            preferences: MockPreferences(),
            dbQueue: queue
        )
        RealisticDataFixture.seedRealisticData(db: db)
        let snapshot = try SnapshotCapturer.capture(db: db)
        let baseline = try Data(contentsOf: Self.baselineFileURL)
        if snapshot != baseline {
            let liveURL = Self.baselineFileURL
                .deletingLastPathComponent()
                .appendingPathComponent("live_snapshot_grdb.json")
            try snapshot.write(to: liveURL)
            XCTFail("GRDB snapshot diverged from baseline. Live: \(liveURL.path)")
        }
    }
}

// MARK: - SnapshotCapturer

/// Captures a deterministic JSON representation of the full LocalDatabase state.
enum SnapshotCapturer {

    static func capture(db: LocalDatabase) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        var root: [String: CapturedEntity] = [:]
        root["customConfigs"]    = try .wrap(captureCustomConfigs(db))
        root["favourites"]       = try .wrap(captureFavourites(db))
        root["locations"]        = try .wrap(captureLocations(db))
        root["mobilePlans"]      = try .wrap(captureMobilePlans(db))
        root["notices"]          = try .wrap(captureNotices(db))
        root["pingData"]         = try .wrap(capturePingData(db))
        root["portMaps"]         = try .wrap(capturePortMaps(db))
        root["readNotices"]      = try .wrap(captureReadNotices(db))
        root["robertFilters"]    = try .wrap(captureRobertFilters(db))
        root["serverMachines"]   = try .wrap(captureServerMachines(db))
        root["staticIPs"]        = try .wrap(captureStaticIPs(db))
        root["suggestedPorts"]   = try .wrap(captureSuggestedPorts(db))
        root["unblockWgParams"]  = try .wrap(captureUnblockWg(db))
        root["wifiNetworks"]     = try .wrap(captureWifiNetworks(db))
        // Sessions, OldSession, and OpenVPN/IKEv2 credentials are excluded —
        // they live in the Keychain via SessionKeychainStore / Preferences,
        // not LocalDatabase. The Keychain stores have their own test suites.

        return try encoder.encode(root)
    }

    // MARK: Per-entity helpers

    private static func captureLocations(_ db: LocalDatabase) -> [LocationDTO] {
        let models = db.getLocations() ?? []
        return models
            .map { LocationDTO(from: $0) }
            .sorted { $0.id < $1.id }
    }

    private static func captureServerMachines(_ db: LocalDatabase) -> [ServerMachineDTO] {
        let objects = db.getServerMachines() ?? []
        return objects
            .map { ServerMachineDTO(from: $0) }
            .sorted { $0.id < $1.id }
    }

    private static func captureStaticIPs(_ db: LocalDatabase) -> [StaticIPDTO] {
        let models = db.getStaticIPs() ?? []
        return models
            .map { StaticIPDTO(from: $0) }
            .sorted { $0.id < $1.id }
    }

    private static func captureFavourites(_ db: LocalDatabase) -> [FavouriteDTO] {
        return db.getFavouriteList()
            .map { FavouriteDTO(from: $0) }
            .sorted { $0.id < $1.id }
    }

    private static func captureCustomConfigs(_ db: LocalDatabase) -> [CustomConfigDTO] {
        return db.getCustomConfigs()
            .map { CustomConfigDTO(from: $0) }
            .sorted { $0.id < $1.id }
    }

    private static func captureWifiNetworks(_ db: LocalDatabase) -> [WifiNetworkDTO] {
        return db.getNetworks()
            .map { WifiNetworkDTO(from: $0) }
            .sorted { $0.ssid < $1.ssid }
    }

    private static func captureNotices(_ db: LocalDatabase) -> [NoticeDTO] {
        return db.getNotifications()
            .map { NoticeDTO(from: $0) }
            .sorted { $0.id < $1.id }
    }

    private static func captureReadNotices(_ db: LocalDatabase) -> [ReadNoticeDTO] {
        // getReadNotices() now returns [Int]? directly — each element is already the notice id.
        let ids = db.getReadNotices() ?? []
        return ids
            .map { ReadNoticeDTO(id: $0) }
            .sorted { $0.id < $1.id }
    }

    private static func captureRobertFilters(_ db: LocalDatabase) -> RobertFiltersDTO? {
        guard let filters = db.getRobertFilters() else { return nil }
        return RobertFiltersDTO(from: filters)
    }

    private static func capturePortMaps(_ db: LocalDatabase) -> [PortMapDTO] {
        let objects = db.getPortMap() ?? []
        return objects
            .map { PortMapDTO(from: $0) }
            .sorted { $0.connectionProtocol < $1.connectionProtocol }
    }

    private static func captureSuggestedPorts(_ db: LocalDatabase) -> [SuggestedPortsDTO] {
        let objects = db.getSuggestedPorts() ?? []
        return objects
            .map { SuggestedPortsDTO(from: $0) }
            .sorted { "\($0.protocolType)-\($0.port)" < "\($1.protocolType)-\($1.port)" }
    }

    private static func captureMobilePlans(_ db: LocalDatabase) -> [MobilePlanDTO] {
        let objects = db.getMobilePlans() ?? []
        return objects
            .map { MobilePlanDTO(from: $0) }
            .sorted { $0.extId < $1.extId }
    }

    private static func captureUnblockWg(_ db: LocalDatabase) -> [UnblockWgParamsDTO] {
        return db.getUnblockWgParams()
            .map { UnblockWgParamsDTO(from: $0) }
            .sorted { $0.id < $1.id }
    }

    private static func capturePingData(_ db: LocalDatabase) -> [PingDataDTO] {
        return db.getAllPingData()
            .map { PingDataDTO(ip: $0.ip, latency: $0.latency) }
            .sorted { $0.ip < $1.ip }
    }
}

// MARK: - Polymorphic root helper

private struct CapturedEntity: Encodable {
    private let _encode: (Encoder) throws -> Void

    static func wrap<E: Encodable>(_ value: E) throws -> CapturedEntity {
        CapturedEntity { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Codable DTOs

// MARK: Location + Datacenter

private struct LocationDTO: Codable {
    let id: Int
    let name: String
    let countryCode: String
    let shortName: String
    let sortOrder: Int
    let continent: String
    let datacenters: [DatacenterDTO]    // sorted by id

    init(from model: LocationModel) {
        id          = model.id
        name        = model.name
        countryCode = model.countryCode
        shortName   = model.shortName
        sortOrder   = model.sortOrder
        continent   = model.continent
        datacenters = model.datacenters
            .map { DatacenterDTO(from: $0) }
            .sorted { $0.id < $1.id }
    }
}

private struct DatacenterDTO: Codable {
    let id: Int
    let city: String
    let nick: String
    let iata: String
    let gps: String
    let tz: String
    let p2p: Int
    let isPremium: Int
    let wgPubkey: String
    let wgEndpoint: String
    let ovpnX509: String
    let linkSpeed: Int

    init(from model: DatacenterModel) {
        id         = model.id
        city       = model.city
        nick       = model.nick
        iata       = model.iata
        gps        = model.gps
        tz         = model.tz
        p2p        = model.p2p
        isPremium  = model.isPremium
        wgPubkey   = model.wgPubkey
        wgEndpoint = model.wgEndpoint
        ovpnX509   = model.ovpnX509
        linkSpeed  = model.linkSpeed
    }
}

// MARK: ServerMachine

private struct ServerMachineDTO: Codable {
    let id: Int
    let hostname: String
    let ip: String
    let ip2: String
    let ip3: String
    let ipv6: Int
    let datacenterId: Int
    let weight: Int
    let netLoad: Int
    let sclass: Int

    init(from obj: ServerMachineModel) {
        id           = obj.id
        hostname     = obj.hostname
        ip           = obj.ip
        ip2          = obj.ip2
        ip3          = obj.ip3
        ipv6         = obj.ipv6
        datacenterId = obj.datacenterId
        weight       = obj.weight
        netLoad      = obj.netLoad
        sclass       = obj.sclass
    }
}

// MARK: StaticIP

private struct StaticIPDTO: Codable {
    let id: Int
    let staticIP: String
    let type: String
    let name: String
    let countryCode: String
    let cityName: String
    let expiry: String?         // ISO8601 or nil
    let isActive: Bool
    let connectIP: String
    let wgIp: String
    let wgPublicKey: String
    let ovpnX509: String
    let pingHost: String
    let deviceName: String
    let nodes: [NodeDTO]              // sorted by hostname
    let credentials: [CredentialsDTO] // sorted by username

    init(from model: StaticIPModel) {
        id          = model.id
        staticIP    = model.staticIP
        type        = model.type
        name        = model.name
        countryCode = model.countryCode
        cityName    = model.cityName
        if let d = model.expiry {
            let fmt = ISO8601DateFormatter()
            expiry = fmt.string(from: d)
        } else {
            expiry = nil
        }
        isActive    = model.isActive
        connectIP   = model.connectIP
        wgIp        = model.wgIp
        wgPublicKey = model.wgPublicKey
        ovpnX509    = model.ovpnX509
        pingHost    = model.pingHost
        deviceName  = model.deviceName
        nodes       = model.nodes.map { NodeDTO(from: $0) }.sorted { $0.hostname < $1.hostname }
        credentials = model.credentials.map { CredentialsDTO(username: $0.username, password: $0.password) }.sorted { $0.username < $1.username }
    }
}

private struct NodeDTO: Codable {
    let ip: String
    let ip2: String
    let ip3: String
    let hostname: String
    let dnsHostname: String
    let weight: Int
    let forceDisconnect: Bool

    init(from model: NodeModel) {
        ip              = model.ip1
        ip2             = model.ip2
        ip3             = model.ip3
        hostname        = model.hostname
        dnsHostname     = model.dnsHostname
        weight          = model.weight
        forceDisconnect = model.forceDisconnect
    }
}

// MARK: Favourite

private struct FavouriteDTO: Codable {
    let id: String
    let pinnedIp: String?
    let pinnedNodeIp: String?

    init(from obj: FavouriteModel) {
        id           = obj.id
        pinnedIp     = obj.pinnedIp
        pinnedNodeIp = obj.pinnedNodeHostname
    }
}

// MARK: CustomConfig

private struct CustomConfigDTO: Codable {
    let id: String
    let name: String
    let serverAddress: String
    let protocolType: String
    let port: String
    let username: String
    let password: String
    let authRequired: Bool
    let saveCredentials: Bool

    init(from obj: CustomConfigModel) {
        id              = obj.id
        name            = obj.name
        serverAddress   = obj.serverAddress
        protocolType    = obj.protocolType
        port            = obj.port
        username        = obj.username
        password        = obj.password
        authRequired    = obj.authRequired
        saveCredentials = obj.saveCredentials
    }
}

// MARK: WifiNetwork

private struct WifiNetworkDTO: Codable {
    let ssid: String
    let status: Bool
    let protocolType: String
    let port: String
    let preferredProtocolStatus: Bool
    let preferredProtocol: String
    let preferredPort: String
    let popupDismissCount: Int
    let dontAskAgainForPreferredProtocol: Bool

    init(from model: WifiNetworkModel) {
        ssid                             = model.SSID
        status                           = model.status
        protocolType                     = model.protocolType
        port                             = model.port
        preferredProtocolStatus          = model.preferredProtocolStatus
        preferredProtocol                = model.preferredProtocol
        preferredPort                    = model.preferredPort
        popupDismissCount                = model.popupDismissCount
        dontAskAgainForPreferredProtocol = model.dontAskAgainForPreferredProtocol
    }
}

// MARK: Notice

private struct NoticeDTO: Codable {
    let id: Int
    let title: String
    let message: String
    let date: Int
    let popup: Bool
    let action: NoticeActionDTO?

    init(from model: NoticeModel) {
        id      = model.id
        title   = model.title
        message = model.message
        date    = model.date
        popup   = model.popup
        action  = model.action.map { NoticeActionDTO(from: $0) }
    }
}

private struct NoticeActionDTO: Codable {
    let type: String?
    let pcpid: String?
    let promoCode: String?
    let label: String?

    init(from model: NoticeActionModel) {
        type      = model.type
        pcpid     = model.pcpid
        promoCode = model.promoCode
        label     = model.label
    }
}

// MARK: ReadNotice

private struct ReadNoticeDTO: Codable {
    let id: Int
}

// MARK: RobertFilters

private struct RobertFiltersDTO: Codable {
    let filters: [RobertFilterDTO]  // sorted by id

    init(from models: [RobertFilterModel]) {
        filters = models
            .map { RobertFilterDTO(from: $0) }
            .sorted { $0.id < $1.id }
    }
}

private struct RobertFilterDTO: Codable {
    let id: String
    let title: String
    let filterDescription: String
    let status: Int
    let enabled: Bool

    init(from obj: RobertFilterModel) {
        id                = obj.id
        title             = obj.title
        filterDescription = obj.filterDescription
        status            = obj.status
        enabled           = obj.enabled
    }
}

// MARK: PortMap

private struct PortMapDTO: Codable {
    let connectionProtocol: String
    let heading: String
    let use: String
    let ports: [String]         // sorted
    let legacyPorts: [String]   // sorted

    init(from obj: PortMapModel) {
        connectionProtocol = obj.connectionProtocol
        heading            = obj.heading
        use                = obj.use
        ports              = obj.ports.sorted()
        legacyPorts        = obj.legacyPorts.sorted()
    }
}

// MARK: SuggestedPorts

private struct SuggestedPortsDTO: Codable {
    let protocolType: String
    let port: String

    init(from obj: SuggestedPortsModel) {
        protocolType = obj.protocolType
        port         = obj.port
    }
}

// MARK: MobilePlan

private struct MobilePlanDTO: Codable {
    let active: Bool
    let extId: String
    let name: String
    let price: String
    let type: String
    let duration: Int
    let discount: Int

    init(from obj: MobilePlanModel) {
        active   = obj.active
        extId    = obj.extId
        name     = obj.name
        price    = obj.price
        type     = obj.type
        duration = obj.duration
        discount = obj.discount
    }
}

// MARK: Per-StaticIP Credentials (nested in StaticIP)

private struct CredentialsDTO: Codable {
    let username: String
    let password: String
}

// MARK: UnblockWgParams

private struct UnblockWgParamsDTO: Codable {
    let id: String
    let title: String
    let countries: [String]     // sorted
    let jc: Int?
    let jMin: Int?
    let jMax: Int?
    let s1: Int?
    let s2: Int?
    let s3: Int?
    let s4: Int?
    let h1: String?
    let h2: String?
    let h3: String?
    let h4: String?
    let i1: String?
    let i2: String?
    let i3: String?
    let i4: String?
    let i5: String?

    init(from obj: UnblockWgParams) {
        id        = obj.id
        title     = obj.title
        countries = obj.countries.sorted()
        jc        = obj.jc
        jMin      = obj.jMin
        jMax      = obj.jMax
        s1        = obj.s1
        s2        = obj.s2
        s3        = obj.s3
        s4        = obj.s4
        h1        = obj.h1
        h2        = obj.h2
        h3        = obj.h3
        h4        = obj.h4
        i1        = obj.i1
        i2        = obj.i2
        i3        = obj.i3
        i4        = obj.i4
        i5        = obj.i5
    }
}

// MARK: PingData

private struct PingDataDTO: Codable {
    let ip: String
    let latency: Int
}

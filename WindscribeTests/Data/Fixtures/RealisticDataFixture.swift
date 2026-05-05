// RealisticDataFixture.swift
// WindscribeTests
//
// Realistic hand-written fixture that seeds a LocalDatabase with every
// persisted entity. Used as the golden baseline for the Realm → GRDB migration.

import Foundation
@testable import Windscribe

enum RealisticDataFixture {
    /// Seed `db` with realistic, hand-written data covering every persisted entity.
    /// Idempotent: callers pass a freshly-empty DB. Do not call `.clean()` internally.
    ///
    /// Sessions, OldSession, and OpenVPN/IKEv2 server credentials are NOT seeded
    /// here — they live in the Keychain via SessionKeychainStore / Preferences
    /// (post-keychain consolidation, !1323), not LocalDatabase.
    static func seedRealisticData(db: LocalDatabase) {
        seedLocations(db)
        seedServerMachines(db)
        seedStaticIPs(db)
        seedFavourites(db)
        seedCustomConfigs(db)
        seedWifiNetworks(db)
        seedNotices(db)
        seedReadNotices(db)
        seedRobertFilters(db)
        seedPortMaps(db)
        seedSuggestedPorts(db)
        seedMobilePlans(db)
        seedUnblockWgParams(db)
        seedPingData(db)
        // Deliberately do NOT seed MyIP — it's deprecated.
    }

    // MARK: - Private helpers

    private static func seedLocations(_ db: LocalDatabase) {
        // US — 2 datacenters
        let dc100 = makeDatacenterModel(
            id: 100, city: "New York", nick: "NYC", iata: "JFK",
            gps: "40.71,-74.01", tz: "America/New_York",
            wgPubkey: "wgkey_us100", wgEndpoint: "10.0.0.100:51820",
            ovpnX509: "US-East", linkSpeed: 1000, status: 1, p2p: 1, isPremium: 0
        )
        let dc101 = makeDatacenterModel(
            id: 101, city: "Los Angeles", nick: "LAX", iata: "LAX",
            gps: "34.05,-118.24", tz: "America/Los_Angeles",
            wgPubkey: "wgkey_us101", wgEndpoint: "10.0.0.101:51820",
            ovpnX509: "US-West", linkSpeed: 1000, status: 1, p2p: 1, isPremium: 0
        )
        let locUS = LocationModel(
            id: 1, name: "United States", countryCode: "US",
            shortName: "US", sortOrder: 0, continent: "NA",
            datacenters: [dc100, dc101]
        )

        // Canada — 1 datacenter
        let dc200 = makeDatacenterModel(
            id: 200, city: "Toronto", nick: "YYZ", iata: "YYZ",
            gps: "43.65,-79.38", tz: "America/Toronto",
            wgPubkey: "wgkey_ca200", wgEndpoint: "10.0.0.200:51820",
            ovpnX509: "CA-Central", linkSpeed: 1000, status: 1, p2p: 1, isPremium: 0
        )
        let locCA = LocationModel(
            id: 2, name: "Canada", countryCode: "CA",
            shortName: "CA", sortOrder: 1, continent: "NA",
            datacenters: [dc200]
        )

        // Japan — 2 datacenters
        let dc300 = makeDatacenterModel(
            id: 300, city: "Tokyo", nick: "TYO", iata: "NRT",
            gps: "35.68,139.69", tz: "Asia/Tokyo",
            wgPubkey: "wgkey_jp300", wgEndpoint: "10.0.0.300:51820",
            ovpnX509: "JP-East", linkSpeed: 1000, status: 1, p2p: 1, isPremium: 0
        )
        let dc301 = makeDatacenterModel(
            id: 301, city: "Osaka", nick: "OSA", iata: "KIX",
            gps: "34.69,135.50", tz: "Asia/Tokyo",
            wgPubkey: "wgkey_jp301", wgEndpoint: "10.0.0.301:51820",
            ovpnX509: "JP-West", linkSpeed: 1000, status: 1, p2p: 1, isPremium: 0
        )
        let locJP = LocationModel(
            id: 3, name: "Japan", countryCode: "JP",
            shortName: "JP", sortOrder: 2, continent: "AS",
            datacenters: [dc300, dc301]
        )

        db.saveLocations(locations: [locUS, locCA, locJP])
    }

    private static func makeDatacenterModel(
        id: Int, city: String, nick: String, iata: String,
        gps: String, tz: String, wgPubkey: String, wgEndpoint: String,
        ovpnX509: String, linkSpeed: Int, status: Int, p2p: Int, isPremium: Int
    ) -> DatacenterModel {
        DatacenterModel(
            id: id, city: city, nick: nick, iata: iata,
            status: status, gps: gps, tz: tz, p2p: p2p,
            isPremium: isPremium, wgPubkey: wgPubkey,
            wgEndpoint: wgEndpoint, ovpnX509: ovpnX509, linkSpeed: linkSpeed
        )
    }

    private static func seedServerMachines(_ db: LocalDatabase) {
        let specs: [(id: Int, dcId: Int, hostname: String)] = [
            (1001, 100, "us-east-1.windscribe.com"),
            (1002, 101, "us-west-1.windscribe.com"),
            (1003, 200, "ca-central-1.windscribe.com"),
            (1004, 300, "jp-east-1.windscribe.com"),
            (1005, 301, "jp-west-1.windscribe.com"),
        ]
        let machines: [ServerMachineModel] = specs.map { spec in
            ServerMachineModel(
                id: spec.id,
                hostname: spec.hostname,
                ip: "1.2.3.4",
                ip2: "1.2.3.5",
                ip3: "1.2.3.6",
                ipv6: 1,
                datacenterId: spec.dcId,
                weight: 100,
                netLoad: 15,
                sclass: 1
            )
        }
        db.saveServerMachines(serverMachines: machines)
    }

    private static func seedStaticIPs(_ db: LocalDatabase) {
        let sip1 = makeStaticIPModel(
            id: 1001, staticIP: "203.0.113.1",
            type: "openvpn", name: "Work VPN",
            countryCode: "US", cityName: "New York",
            expiryString: "2027-01-01",
            connectIP: "203.0.113.1", wgIp: "10.64.0.1",
            wgPublicKey: "wgpub_sip1", ovpnX509: "SIP-1",
            pingHost: "ping1.example.com",
            deviceName: "iPhone"
        )
        let sip2 = makeStaticIPModel(
            id: 1002, staticIP: "203.0.113.2",
            type: "openvpn", name: "Home VPN",
            countryCode: "US", cityName: "Los Angeles",
            expiryString: "2027-06-01",
            connectIP: "203.0.113.2", wgIp: "10.64.0.2",
            wgPublicKey: "wgpub_sip2", ovpnX509: "SIP-2",
            pingHost: "ping2.example.com",
            deviceName: "iPhone"
        )
        db.saveStaticIPs(staticIps: [sip1, sip2])
    }

    private static func makeStaticIPModel(
        id: Int, staticIP: String, type: String, name: String,
        countryCode: String, cityName: String,
        expiryString: String, connectIP: String,
        wgIp: String, wgPublicKey: String, ovpnX509: String,
        pingHost: String, deviceName: String
    ) -> StaticIPModel {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let expiry = df.date(from: expiryString)

        let node = NodeModel(
            ip1: "1.2.3.4",
            ip2: "1.2.3.5",
            ip3: "1.2.3.6",
            hostname: "node1.example.com",
            dnsHostname: "dns.node1.example.com",
            forceDisconnect: false,
            weight: 100
        )
        let creds = ServerCredentialsModel(username: "stat_user", password: "stat_pass")

        return StaticIPModel(
            id: id,
            staticIP: staticIP,
            connectIP: connectIP,
            type: type,
            name: name,
            countryCode: countryCode,
            deviceName: deviceName,
            cityName: cityName,
            expiry: expiry,
            isActive: true,
            credentials: [creds],
            wgPublicKey: wgPublicKey,
            ovpnX509: ovpnX509,
            wgIp: wgIp,
            pingHost: pingHost,
            nodes: [node]
        )
    }

    private static func seedFavourites(_ db: LocalDatabase) {
        let fav1 = FavouriteModel(id: "fav-dc-100", pinnedIp: nil, pinnedNodeHostname: nil)
        let fav2 = FavouriteModel(id: "fav-dc-200", pinnedIp: "1.2.3.4", pinnedNodeHostname: "host1.example.com")
        let fav3 = FavouriteModel(id: "fav-dc-300", pinnedIp: nil, pinnedNodeHostname: "host2.example.com")
        db.saveFavourite(favourite: fav1)
        db.saveFavourite(favourite: fav2)
        db.saveFavourite(favourite: fav3)
    }

    private static func seedCustomConfigs(_ db: LocalDatabase) {
        let cc1 = CustomConfigModel(
            id: "11111111-1111-1111-1111-111111111111",
            name: "Home VPN",
            serverAddress: "home.vpn.example.com",
            protocolType: "openvpn",
            port: "443",
            username: "home_user",
            password: "home_pass",
            authRequired: true,
            saveCredentials: true
        )
        let cc2 = CustomConfigModel(
            id: "22222222-2222-2222-2222-222222222222",
            name: "Office VPN",
            serverAddress: "office.vpn.example.com",
            protocolType: "wireguard",
            port: "51820",
            username: "office_user",
            password: "office_pass",
            authRequired: true,
            saveCredentials: true
        )
        db.saveCustomConfig(customConfig: cc1)
        db.saveCustomConfig(customConfig: cc2)
    }

    private static func seedWifiNetworks(_ db: LocalDatabase) {
        var home = WifiNetworkModel(
            SSID: "HomeNet",
            status: true,
            protocolType: "WireGuard",
            port: "443",
            preferredProtocol: "WireGuard",
            preferredPort: "443",
            preferredProtocolStatus: true
        )
        home.popupDismissCount = 0
        home.dontAskAgainForPreferredProtocol = false

        var work = WifiNetworkModel(
            SSID: "WorkNet",
            status: false,
            protocolType: "OpenVPN",
            port: "1194",
            preferredProtocol: "OpenVPN",
            preferredPort: "1194",
            preferredProtocolStatus: false
        )
        work.popupDismissCount = 2
        work.dontAskAgainForPreferredProtocol = false

        var coffee = WifiNetworkModel(
            SSID: "CoffeeShop",
            status: false,
            protocolType: "IKEv2",
            port: "500",
            preferredProtocol: "IKEv2",
            preferredPort: "500",
            preferredProtocolStatus: false
        )
        coffee.popupDismissCount = 5
        coffee.dontAskAgainForPreferredProtocol = true

        db.saveNetwork(wifiNetwork: home)
        db.saveNetwork(wifiNetwork: work)
        db.saveNetwork(wifiNetwork: coffee)
    }

    private static func seedNotices(_ db: LocalDatabase) {
        // Notice 1: popup with action
        let action1 = NoticeActionModel(
            type: "openUrl",
            pcpid: "123",
            promoCode: "PROMO2026",
            label: "Upgrade"
        )
        let notice1 = NoticeModel(
            id: 1,
            title: "Limited Time Offer",
            message: "Upgrade to Pro and save 50% today.",
            date: 1_700_000_000,
            popup: true,
            action: action1
        )

        // Notice 2: non-popup, no action
        let notice2 = NoticeModel(
            id: 2,
            title: "Maintenance Scheduled",
            message: "Brief maintenance on 2026-06-01 at 02:00 UTC.",
            date: 1_700_100_000,
            popup: false,
            action: nil
        )

        // Notice 3: popup, no action
        let notice3 = NoticeModel(
            id: 3,
            title: "New Feature Available",
            message: "AmneziaWG is now available for all Pro users.",
            date: 1_700_200_000,
            popup: true,
            action: nil
        )

        db.saveNotifications(notifications: [notice1, notice2, notice3])
    }

    private static func seedReadNotices(_ db: LocalDatabase) {
        db.saveReadNotices(readNotices: [1, 3])
    }

    private static func seedRobertFilters(_ db: LocalDatabase) {
        let ads = RobertFilterModel(id: "ads", title: "Ads",
                                    filterDescription: "Block ads", status: 1, enabled: true)
        let trackers = RobertFilterModel(id: "trackers", title: "Trackers",
                                         filterDescription: "Block trackers", status: 1, enabled: true)
        let adult = RobertFilterModel(id: "adult", title: "Adult",
                                      filterDescription: "Block adult content", status: 0, enabled: false)
        let malware = RobertFilterModel(id: "malware", title: "Malware",
                                        filterDescription: "Block malware", status: 1, enabled: true)
        db.saveRobertFilters(filters: [ads, trackers, adult, malware])
    }

    private static func seedPortMaps(_ db: LocalDatabase) {
        let pm1 = PortMapModel(
            connectionProtocol: "OpenVPN",
            heading: "UDP",
            use: "default",
            ports: ["443", "1194", "4443"],
            legacyPorts: ["80"]
        )
        let pm2 = PortMapModel(
            connectionProtocol: "WireGuard",
            heading: "WireGuard",
            use: "default",
            ports: ["51820", "443"],
            legacyPorts: []
        )
        db.savePortMap(portMap: [pm1, pm2])
    }

    private static func seedSuggestedPorts(_ db: LocalDatabase) {
        let sp = SuggestedPortsModel(protocolType: "WireGuard", port: "51820")
        db.saveSuggestedPorts(suggestedPorts: [sp])
    }

    private static func seedMobilePlans(_ db: LocalDatabase) {
        let monthly = MobilePlanModel(
            active: true, extId: "com.windscribe.monthly", name: "Monthly",
            price: "$9.99", type: "subscription", duration: 1, discount: 0
        )
        let yearly = MobilePlanModel(
            active: true, extId: "com.windscribe.yearly", name: "Yearly",
            price: "$49", type: "subscription", duration: 12, discount: 30
        )
        let biennial = MobilePlanModel(
            active: false, extId: "com.windscribe.biennial", name: "Biennial",
            price: "$89", type: "subscription", duration: 24, discount: 50
        )
        db.saveMobilePlans(mobilePlansList: [monthly, yearly, biennial])
    }

    private static func seedUnblockWgParams(_ db: LocalDatabase) {
        // The UnblockWgParamsObj Realm class has a latent bug where only the @Persisted `id`
        // round-trips (other fields are plain `dynamic var` without @Persisted). We don't fix
        // that because Realm is being deleted next release. Fixture matches production
        // reality: only `id` is round-trippable; other fields get re-fetched from the API.
        // This keeps the snapshot equivalent across Realm and GRDB backings.
        let p1 = UnblockWgParams(
            id: "awg-01", title: "", countries: [],
            jc: nil, jMin: nil, jMax: nil,
            s1: nil, s2: nil, s3: nil, s4: nil,
            h1: nil, h2: nil, h3: nil, h4: nil,
            i1: nil, i2: nil, i3: nil, i4: nil, i5: nil
        )
        let p2 = UnblockWgParams(
            id: "awg-02", title: "", countries: [],
            jc: nil, jMin: nil, jMax: nil,
            s1: nil, s2: nil, s3: nil, s4: nil,
            h1: nil, h2: nil, h3: nil, h4: nil,
            i1: nil, i2: nil, i3: nil, i4: nil, i5: nil
        )

        db.saveUnblockWgParams(params: [p1, p2])
    }

    private static func seedPingData(_ db: LocalDatabase) {
        let entries: [(ip: String, latency: Int)] = [
            ("1.2.3.4", 25),
            ("5.6.7.8", 50),
            ("9.10.11.12", 100),
            ("13.14.15.16", 150),
            ("17.18.19.20", -1),   // not yet measured
        ]
        for entry in entries {
            db.addPingData(pingData: PingDataModel(ip: entry.ip, latency: entry.latency))
        }
    }
}

import Foundation
import GRDB

/// Canonical table-name registry for the GRDB schema. Every `databaseTableName`
/// on a Record and every `db.create(table:)` call in `GRDBSchema` sources its
/// string from here. Do NOT duplicate these literals elsewhere — a typo in one
/// place and not the other would silently target a nonexistent table.
///
/// Sessions, OldSession, and OpenVPN/IKEv2 server credentials are NOT in this
/// schema. They live in the iOS Keychain via `SessionKeychainStore` /
/// `Preferences+Keychain` (landed in MR !1323). GRDB's job is the rest of the
/// Realm-resident state.
enum Tables {
    static let location                 = "location"
    static let serverMachine            = "server_machine"
    static let staticIP                 = "static_ip"
    static let favourite                = "favourite"
    static let customConfig             = "custom_config"
    static let wifiNetwork              = "wifi_network"
    static let notice                   = "notice"
    static let readNotice               = "read_notice"
    static let robertFiltersSingleton   = "robert_filters_singleton"
    static let portMap                  = "port_map"
    static let suggestedPorts           = "suggested_ports"
    static let mobilePlan               = "mobile_plan"
    static let unblockWgParams          = "unblock_wg_params"
    static let pingData                 = "ping_data"
}

/// GRDB schema for Windscribe's local database. Replaces Realm.
/// v1 mirrors the current Realm schema shape 1:1 — no normalization.
/// Schema improvements (drop dead fields, flatten single-element lists,
/// proper FKs, rename mislabeled columns) are deferred to a follow-up PR.
enum GRDBSchema {

    /// The set of tables in the v1 schema. `clean()` iterates this list;
    /// `favourite` is explicitly NOT in the iteration (preserved on logout).
    static let allTables: [String] = [
        Tables.location, Tables.serverMachine,
        Tables.staticIP,
        Tables.customConfig, Tables.wifiNetwork,
        Tables.notice, Tables.readNotice,
        Tables.robertFiltersSingleton,
        Tables.portMap, Tables.suggestedPorts, Tables.mobilePlan,
        Tables.unblockWgParams, Tables.pingData
        // Deliberately excludes `Tables.favourite` — retained across clean().
    ]

    /// Tables preserved across `clean()` (logout). Matches the current
    /// Realm `doNotDeleteObjects` list (only Favourite).
    static let cleanSkipTables: [String] = [Tables.favourite]

    /// The DatabaseMigrator. v1 creates every table.
    static func makeMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try createLocation(db)
            try createServerMachine(db)
            try createStaticIP(db)
            try createFavourite(db)
            try createCustomConfig(db)
            try createWifiNetwork(db)
            try createNotice(db)
            try createReadNotice(db)
            try createRobertFiltersSingleton(db)
            try createPortMap(db)
            try createSuggestedPorts(db)
            try createMobilePlan(db)
            try createUnblockWgParams(db)
            try createPingData(db)
        }
        return migrator
    }

    // MARK: - Per-table create functions

    private static func createLocation(_ db: GRDB.Database) throws {
        try db.create(table: Tables.location) { t in
            t.primaryKey("id", .integer).notNull()
            t.column("sort_order", .integer)
            t.column("name", .text).notNull().defaults(to: "")
            t.column("country_code", .text).notNull().defaults(to: "")
            t.column("short_name", .text).notNull().defaults(to: "")
            t.column("continent", .text).notNull().defaults(to: "")
            // JSON-encoded array of datacenter objects
            t.column("datacenters_json", .text).notNull().defaults(to: "[]")
        }
    }

    private static func createServerMachine(_ db: GRDB.Database) throws {
        try db.create(table: Tables.serverMachine) { t in
            t.primaryKey("id", .integer).notNull()
            t.column("hostname", .text).notNull().defaults(to: "")
            t.column("ip", .text).notNull().defaults(to: "")
            t.column("ip2", .text).notNull().defaults(to: "")
            t.column("ip3", .text).notNull().defaults(to: "")
            t.column("ipv6", .integer).notNull().defaults(to: 0)
            t.column("datacenter_id", .integer).notNull().defaults(to: 0)
            t.column("weight", .integer).notNull().defaults(to: 0)
            t.column("net_load", .integer).notNull().defaults(to: 0)
            t.column("sclass", .integer).notNull().defaults(to: 0)
        }
    }

    private static func createStaticIP(_ db: GRDB.Database) throws {
        try db.create(table: Tables.staticIP) { t in
            t.primaryKey("id", .integer).notNull()
            t.column("ip_id", .integer)
            t.column("static_ip", .text)
            t.column("type", .text)
            t.column("name", .text)
            t.column("country_code", .text)
            t.column("short_name", .text)
            t.column("city_name", .text)
            t.column("server_id", .integer)
            t.column("expiry", .text)
            t.column("is_active", .integer)
            t.column("connect_ip", .text)
            t.column("wg_ip", .text)
            t.column("wg_public_key", .text)
            t.column("ovpn_x509", .text)
            t.column("ping_ip", .text)
            t.column("ping_host", .text)
            t.column("device_name", .text)
            // JSON-encoded arrays
            t.column("nodes_json", .text).notNull().defaults(to: "[]")
            t.column("ports_json", .text).notNull().defaults(to: "[]")
            t.column("credentials_json", .text).notNull().defaults(to: "[]")
        }
    }

    private static func createFavourite(_ db: GRDB.Database) throws {
        try db.create(table: Tables.favourite) { t in
            t.primaryKey("id", .text).notNull()
            t.column("pinned_ip", .text)
            // NOTE: named pinned_node_ip in Realm even though it stores a hostname.
            // Rename is deferred to the normalization PR.
            t.column("pinned_node_ip", .text)
        }
    }

    private static func createCustomConfig(_ db: GRDB.Database) throws {
        try db.create(table: Tables.customConfig) { t in
            t.primaryKey("id", .text).notNull()
            t.column("name", .text)
            t.column("server_address", .text)
            t.column("protocol_type", .text)
            t.column("port", .text)
            t.column("username", .text)
            t.column("password", .text)
            t.column("auth_required", .integer)
            t.column("save_credentials", .integer)
        }
    }

    private static func createWifiNetwork(_ db: GRDB.Database) throws {
        try db.create(table: Tables.wifiNetwork) { t in
            t.primaryKey("ssid", .text).notNull()
            t.column("status", .integer)
            t.column("protocol_type", .text)
            t.column("port", .text)
            t.column("preferred_protocol_status", .integer)
            t.column("preferred_protocol", .text)
            t.column("preferred_port", .text)
            t.column("popup_dismiss_count", .integer)
            t.column("dont_ask_again_for_preferred_protocol", .integer)
        }
    }

    private static func createNotice(_ db: GRDB.Database) throws {
        try db.create(table: Tables.notice) { t in
            t.primaryKey("id", .integer).notNull()
            t.column("title", .text)
            t.column("message", .text)
            t.column("date", .integer)
            t.column("popup", .integer)
            t.column("perm_free", .integer)
            t.column("perm_pro", .integer)
            // Nullable — NoticeAction JSON or NULL
            t.column("action_json", .text)
        }
    }

    private static func createReadNotice(_ db: GRDB.Database) throws {
        try db.create(table: Tables.readNotice) { t in
            t.primaryKey("id", .integer).notNull()
        }
    }

    private static func createRobertFiltersSingleton(_ db: GRDB.Database) throws {
        try db.create(table: Tables.robertFiltersSingleton) { t in
            // id is always "1"
            t.primaryKey("id", .text).notNull()
            // JSON array of RobertFilter objects
            t.column("filters_json", .text).notNull().defaults(to: "[]")
        }
    }

    private static func createPortMap(_ db: GRDB.Database) throws {
        try db.create(table: Tables.portMap) { t in
            t.primaryKey("connection_protocol", .text).notNull()
            t.column("heading", .text)
            t.column("use", .text)
            t.column("ports_json", .text).notNull().defaults(to: "[]")
            t.column("legacy_ports_json", .text).notNull().defaults(to: "[]")
        }
    }

    private static func createSuggestedPorts(_ db: GRDB.Database) throws {
        try db.create(table: Tables.suggestedPorts) { t in
            // id is always "SuggestedPorts"
            t.primaryKey("id", .text).notNull()
            t.column("protocol_type", .text)
            t.column("port", .text)
        }
    }

    private static func createMobilePlan(_ db: GRDB.Database) throws {
        try db.create(table: Tables.mobilePlan) { t in
            t.primaryKey("ext_id", .text).notNull()
            t.column("active", .integer)
            t.column("name", .text)
            t.column("price", .text)
            t.column("type", .text)
            t.column("duration", .integer)
            t.column("discount", .integer)
        }
    }

    private static func createUnblockWgParams(_ db: GRDB.Database) throws {
        try db.create(table: Tables.unblockWgParams) { t in
            t.primaryKey("id", .text).notNull()
            t.column("title", .text)
            t.column("countries_json", .text).notNull().defaults(to: "[]")
            t.column("jc", .integer)
            t.column("j_min", .integer)
            t.column("j_max", .integer)
            t.column("s1", .integer)
            t.column("s2", .integer)
            t.column("s3", .integer)
            t.column("s4", .integer)
            t.column("h1", .text)
            t.column("h2", .text)
            t.column("h3", .text)
            t.column("h4", .text)
            t.column("i1", .text)
            t.column("i2", .text)
            t.column("i3", .text)
            t.column("i4", .text)
            t.column("i5", .text)
        }
    }

    private static func createPingData(_ db: GRDB.Database) throws {
        try db.create(table: Tables.pingData) { t in
            t.primaryKey("ip", .text).notNull()
            t.column("latency", .integer).notNull().defaults(to: -1)
        }
    }
}

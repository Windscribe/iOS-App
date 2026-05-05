// StaticIPRecord.swift
// Windscribe
//
// GRDB Record for the `static_ip` table.

import Foundation
import GRDB

struct StaticIPRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.staticIP

    // MARK: - Flat columns
    var id: Int
    var ipId: Int
    var staticIP: String
    var type: String
    var name: String
    var countryCode: String
    var shortName: String
    var cityName: String
    var serverId: Int
    var expiry: String?       // ISO8601 string; nullable mirrors Realm Date?
    var isActive: Bool
    var connectIP: String
    var wgIp: String
    var wgPublicKey: String
    var ovpnX509: String
    var pingIP: String
    var pingHost: String
    var deviceName: String

    // MARK: - JSON columns
    var nodesJson: String       // JSON [NodeModel]
    var portsJson: String       // JSON [PortDetails] — always "[]"; schema-only
    var credentialsJson: String // JSON [ServerCredentialsModel]

    // MARK: - CodingKeys (camelCase ↔ snake_case)
    enum CodingKeys: String, CodingKey {
        case id
        case ipId            = "ip_id"
        case staticIP        = "static_ip"
        case type
        case name
        case countryCode     = "country_code"
        case shortName       = "short_name"
        case cityName        = "city_name"
        case serverId        = "server_id"
        case expiry
        case isActive        = "is_active"
        case connectIP       = "connect_ip"
        case wgIp            = "wg_ip"
        case wgPublicKey     = "wg_public_key"
        case ovpnX509        = "ovpn_x509"
        case pingIP          = "ping_ip"
        case pingHost        = "ping_host"
        case deviceName      = "device_name"
        case nodesJson       = "nodes_json"
        case portsJson       = "ports_json"
        case credentialsJson = "credentials_json"
    }

    // MARK: - init(from model:)
    init(from model: StaticIPModel) {
        id           = model.id
        ipId         = 0   // StaticIPModel doesn't carry ipId; default to 0
        staticIP     = model.staticIP
        type         = model.type
        name         = model.name
        countryCode  = model.countryCode
        shortName    = ""  // StaticIPModel doesn't carry shortName; default to ""
        cityName     = model.cityName
        serverId     = 0   // StaticIPModel doesn't carry serverId; default to 0
        isActive     = model.isActive
        connectIP    = model.connectIP
        wgIp         = model.wgIp
        wgPublicKey  = model.wgPublicKey
        ovpnX509     = model.ovpnX509
        pingIP       = ""  // StaticIPModel doesn't carry pingIP; default to ""
        pingHost     = model.pingHost
        deviceName   = model.deviceName

        // expiry: Date? → ISO8601 String?
        if let date = model.expiry {
            expiry = ISO8601DateFormatter().string(from: date)
        } else {
            expiry = nil
        }

        let encoder = JSONEncoder()
        nodesJson = (try? String(data: encoder.encode(model.nodes), encoding: .utf8)) ?? "[]"
        portsJson = "[]"
        credentialsJson = (try? String(data: encoder.encode(model.credentials), encoding: .utf8)) ?? "[]"
    }

    // MARK: - toModel()
    func toModel() -> StaticIPModel {
        let decoder = JSONDecoder()
        let nodes: [NodeModel] = (try? decoder.decode(
            [NodeModel].self,
            from: Data(nodesJson.utf8)
        )) ?? []
        let credentials: [ServerCredentialsModel] = (try? decoder.decode(
            [ServerCredentialsModel].self,
            from: Data(credentialsJson.utf8)
        )) ?? []

        var expiryDate: Date?
        if let s = expiry {
            expiryDate = ISO8601DateFormatter().date(from: s)
        }

        return StaticIPModel(
            id: id,
            staticIP: staticIP,
            connectIP: connectIP,
            type: type,
            name: name,
            countryCode: countryCode,
            deviceName: deviceName,
            cityName: cityName,
            expiry: expiryDate,
            isActive: isActive,
            credentials: credentials,
            wgPublicKey: wgPublicKey,
            ovpnX509: ovpnX509,
            wgIp: wgIp,
            pingHost: pingHost,
            nodes: nodes
        )
    }
}

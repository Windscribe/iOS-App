import Foundation
import GRDB

/// GRDB row type for the `server_machine` table.
/// Exists inside the persistence layer — never flows through repositories or views.
/// Use `init(from: ServerMachineModel)` to construct from a domain model, `toModel()` to project back.
struct ServerMachineRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.serverMachine

    // MARK: - Columns

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

    enum CodingKeys: String, CodingKey {
        case id
        case hostname
        case ip
        case ip2
        case ip3
        case ipv6
        case datacenterId = "datacenter_id"
        case weight
        case netLoad      = "net_load"
        case sclass
    }

    // MARK: - Domain ↔ Record

    init(from model: ServerMachineModel) {
        id           = model.id
        hostname     = model.hostname
        ip           = model.ip
        ip2          = model.ip2
        ip3          = model.ip3
        ipv6         = model.ipv6
        datacenterId = model.datacenterId
        weight       = model.weight
        netLoad      = model.netLoad
        sclass       = model.sclass
    }

    func toModel() -> ServerMachineModel {
        ServerMachineModel(
            id:          id,
            hostname:    hostname,
            ip:          ip,
            ip2:         ip2,
            ip3:         ip3,
            ipv6:        ipv6,
            datacenterId: datacenterId,
            weight:      weight,
            netLoad:     netLoad,
            sclass:      sclass
        )
    }
}

import Foundation
import GRDB

/// GRDB row type for the `favourite` table.
struct FavouriteRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.favourite

    // MARK: - Columns

    let id: String
    let pinnedIp: String?
    /// Column is named pinned_node_ip (Realm's misleading name). Rename deferred.
    let pinnedNodeIp: String?

    enum CodingKeys: String, CodingKey {
        case id
        case pinnedIp     = "pinned_ip"
        case pinnedNodeIp = "pinned_node_ip"
    }

    // MARK: - Domain ↔ Record

    init(from model: FavouriteModel) {
        id           = model.id
        pinnedIp     = model.pinnedIp
        pinnedNodeIp = model.pinnedNodeHostname
    }

    func toModel() -> FavouriteModel {
        FavouriteModel(
            id:                   id,
            pinnedIp:             pinnedIp,
            pinnedNodeHostname:   pinnedNodeIp
        )
    }
}

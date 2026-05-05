import Foundation
import GRDB

/// GRDB row type for the `suggested_ports` table.
/// The `id` column is always `"SuggestedPorts"`.
struct SuggestedPortsRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.suggestedPorts

    static let fixedId = "SuggestedPorts"

    // MARK: - Columns

    let id: String
    let protocolType: String?
    let port: String?

    enum CodingKeys: String, CodingKey {
        case id
        case protocolType = "protocol_type"
        case port
    }

    // MARK: - Domain ↔ Record

    init(from model: SuggestedPortsModel) {
        id           = Self.fixedId
        protocolType = model.protocolType
        port         = model.port
    }

    func toModel() -> SuggestedPortsModel {
        SuggestedPortsModel(
            protocolType: protocolType ?? "",
            port:         port ?? ""
        )
    }
}

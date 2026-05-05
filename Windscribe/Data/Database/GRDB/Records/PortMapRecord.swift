import Foundation
import GRDB

/// GRDB row type for the `port_map` table.
/// `ports` and `legacyPorts` are stored as JSON strings.
struct PortMapRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.portMap

    // MARK: - Columns

    let connectionProtocol: String
    let heading: String?
    let use: String?
    /// JSON-encoded `[String]`
    let portsJson: String
    /// JSON-encoded `[String]`
    let legacyPortsJson: String

    enum CodingKeys: String, CodingKey {
        case connectionProtocol = "connection_protocol"
        case heading
        case use
        case portsJson          = "ports_json"
        case legacyPortsJson    = "legacy_ports_json"
    }

    // MARK: - Domain ↔ Record

    init(from model: PortMapModel) {
        connectionProtocol = model.connectionProtocol
        heading            = model.heading
        use                = model.use

        let encoder = JSONEncoder()
        portsJson       = (try? encoder.encode(model.ports))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        legacyPortsJson = (try? encoder.encode(model.legacyPorts))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }

    func toModel() -> PortMapModel {
        let decoder = JSONDecoder()
        let ports: [String]       = (portsJson.data(using: .utf8)
            .flatMap { try? decoder.decode([String].self, from: $0) }) ?? []
        let legacyPorts: [String] = (legacyPortsJson.data(using: .utf8)
            .flatMap { try? decoder.decode([String].self, from: $0) }) ?? []

        return PortMapModel(
            connectionProtocol: connectionProtocol,
            heading:            heading ?? "",
            use:                use ?? "",
            ports:              ports,
            legacyPorts:        legacyPorts
        )
    }
}

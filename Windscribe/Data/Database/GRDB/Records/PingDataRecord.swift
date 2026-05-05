import Foundation
import GRDB

/// GRDB row type for the `ping_data` table.
struct PingDataRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.pingData

    // MARK: - Columns

    let ip: String
    let latency: Int

    // MARK: - Domain ↔ Record

    init(from model: PingDataModel) {
        ip      = model.ip
        latency = model.latency
    }

    func toModel() -> PingDataModel {
        PingDataModel(ip: ip, latency: latency)
    }
}

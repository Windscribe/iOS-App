import Foundation
import GRDB

/// GRDB row type for the `location` table.
/// Exists inside the persistence layer — never flows through repositories or views.
/// Use `init(from: LocationModel)` to construct from a domain model, `toModel()` to project back.
struct LocationRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.location

    // MARK: - Columns

    let id: Int
    let sortOrder: Int
    let name: String
    let countryCode: String
    let shortName: String
    let continent: String
    /// JSON-encoded `[DatacenterModel]`.
    let datacentersJson: String

    enum CodingKeys: String, CodingKey {
        case id
        case sortOrder       = "sort_order"
        case name
        case countryCode     = "country_code"
        case shortName       = "short_name"
        case continent
        case datacentersJson = "datacenters_json"
    }

    // MARK: - Domain ↔ Record

    init(from model: LocationModel) {
        id           = model.id
        sortOrder    = model.sortOrder
        name         = model.name
        countryCode  = model.countryCode
        shortName    = model.shortName
        continent    = model.continent

        let encoder = JSONEncoder()
        datacentersJson = (try? encoder.encode(model.datacenters))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }

    func toModel() -> LocationModel {
        let decoder = JSONDecoder()
        let datacenters = (datacentersJson.data(using: .utf8)
            .flatMap { try? decoder.decode([DatacenterModel].self, from: $0) }) ?? []

        return LocationModel(
            id:          id,
            name:        name,
            countryCode: countryCode,
            shortName:   shortName,
            sortOrder:   sortOrder,
            continent:   continent,
            datacenters: datacenters
        )
    }
}

// RobertFiltersRecord.swift
// Windscribe
//
// GRDB Record for the `robert_filters_singleton` table.

import Foundation
import GRDB

struct RobertFiltersRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.robertFiltersSingleton

    // MARK: - Columns
    var id: String           // always "1"
    var filtersJson: String  // JSON [RobertFilterModel]

    // MARK: - CodingKeys (camelCase ↔ snake_case)
    enum CodingKeys: String, CodingKey {
        case id
        case filtersJson = "filters_json"
    }

    // MARK: - init(from models:)
    init(from models: [RobertFilterModel]) {
        id = "1"
        let encoder = JSONEncoder()
        filtersJson = (try? String(data: encoder.encode(models), encoding: .utf8)) ?? "[]"
    }

    // MARK: - toModel()
    func toModel() -> [RobertFilterModel] {
        (try? JSONDecoder().decode([RobertFilterModel].self, from: Data(filtersJson.utf8))) ?? []
    }
}

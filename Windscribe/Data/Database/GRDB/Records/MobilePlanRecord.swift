import Foundation
import GRDB

/// GRDB row type for the `mobile_plan` table.
struct MobilePlanRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.mobilePlan

    // MARK: - Columns

    let extId: String
    let active: Bool?
    let name: String?
    let price: String?
    let type: String?
    let duration: Int?
    let discount: Int?

    enum CodingKeys: String, CodingKey {
        case extId    = "ext_id"
        case active
        case name
        case price
        case type
        case duration
        case discount
    }

    // MARK: - Domain ↔ Record

    init(from model: MobilePlanModel) {
        extId    = model.extId
        active   = model.active
        name     = model.name
        price    = model.price
        type     = model.type
        duration = model.duration
        discount = model.discount
    }

    func toModel() -> MobilePlanModel {
        MobilePlanModel(
            active:   active ?? false,
            extId:    extId,
            name:     name ?? "",
            price:    price ?? "",
            type:     type ?? "",
            duration: duration ?? 0,
            discount: discount ?? 0
        )
    }
}

import Foundation
import GRDB

/// GRDB row type for the `unblock_wg_params` table.
/// `countries` is stored as a JSON string; all other fields are flat.
struct UnblockWgParamsRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.unblockWgParams

    // MARK: - Columns

    let id: String
    let title: String?
    /// JSON-encoded `[String]`
    let countriesJson: String
    let jc: Int?
    let jMin: Int?
    let jMax: Int?
    let s1: Int?
    let s2: Int?
    let s3: Int?
    let s4: Int?
    let h1: String?
    let h2: String?
    let h3: String?
    let h4: String?
    let i1: String?
    let i2: String?
    let i3: String?
    let i4: String?
    let i5: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case countriesJson = "countries_json"
        case jc
        case jMin          = "j_min"
        case jMax          = "j_max"
        case s1, s2, s3, s4
        case h1, h2, h3, h4
        case i1, i2, i3, i4, i5
    }

    // MARK: - Domain ↔ Record

    init(from model: UnblockWgParams) {
        id    = model.id
        title = model.title
        jc    = model.jc
        jMin  = model.jMin
        jMax  = model.jMax
        s1    = model.s1
        s2    = model.s2
        s3    = model.s3
        s4    = model.s4
        h1    = model.h1
        h2    = model.h2
        h3    = model.h3
        h4    = model.h4
        i1    = model.i1
        i2    = model.i2
        i3    = model.i3
        i4    = model.i4
        i5    = model.i5

        let encoder = JSONEncoder()
        countriesJson = (try? encoder.encode(model.countries))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }

    func toModel() -> UnblockWgParams {
        let decoder = JSONDecoder()
        let countries: [String] = (countriesJson.data(using: .utf8)
            .flatMap { try? decoder.decode([String].self, from: $0) }) ?? []

        return UnblockWgParams(
            id:       id,
            title:    title ?? "",
            countries: countries,
            jc:       jc,
            jMin:     jMin,
            jMax:     jMax,
            s1:       s1,
            s2:       s2,
            s3:       s3,
            s4:       s4,
            h1:       h1,
            h2:       h2,
            h3:       h3,
            h4:       h4,
            i1:       i1,
            i2:       i2,
            i3:       i3,
            i4:       i4,
            i5:       i5
        )
    }
}

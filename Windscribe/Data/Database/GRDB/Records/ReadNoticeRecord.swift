import Foundation
import GRDB

/// GRDB row type for the `read_notice` table.
/// No domain model — the repository works with `[Int]` directly.
struct ReadNoticeRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.readNotice

    // MARK: - Columns

    let id: Int

    // MARK: - Memberwise init

    init(id: Int) {
        self.id = id
    }

    /// Convenience projection — returns the notice id directly.
    func toModel() -> Int { id }
}

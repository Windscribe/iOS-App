// NoticeRecord.swift
// Windscribe
//
// GRDB Record for the `notice` table.

import Foundation
import GRDB

struct NoticeRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.notice

    // MARK: - Flat columns
    var id: Int
    var title: String
    var message: String
    var date: Int
    var popup: Bool
    var permFree: Bool  // dead at Model layer; kept for schema 1:1
    var permPro: Bool   // dead at Model layer; kept for schema 1:1

    // MARK: - Nullable JSON column
    var actionJson: String?  // JSON NoticeActionModel, or nil

    // MARK: - CodingKeys (camelCase ↔ snake_case)
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case date
        case popup
        case permFree  = "perm_free"
        case permPro   = "perm_pro"
        case actionJson = "action_json"
    }

    // MARK: - init(from model:)
    init(from model: NoticeModel) {
        id       = model.id
        title    = model.title
        message  = model.message
        date     = model.date
        popup    = model.popup
        permFree = false   // dead field — always false
        permPro  = false   // dead field — always false

        if let action = model.action {
            let encoder = JSONEncoder()
            actionJson = try? String(data: encoder.encode(action), encoding: .utf8)
        } else {
            actionJson = nil
        }
    }

    // MARK: - toModel()
    func toModel() -> NoticeModel {
        var action: NoticeActionModel?
        if let json = actionJson {
            action = try? JSONDecoder().decode(NoticeActionModel.self, from: Data(json.utf8))
        }
        return NoticeModel(
            id: id,
            title: title,
            message: message,
            date: date,
            popup: popup,
            action: action
        )
    }
}

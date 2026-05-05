//
//  Notice.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-14.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct NoticeActionModel: Codable, Equatable {
    let type: String?
    let pcpid: String?
    let promoCode: String?
    let label: String?

    init(from: NoticeAction) {
        self.type = from.type
        self.pcpid = from.pcpid
        self.promoCode = from.promoCode
        self.label = from.label
    }

    init(type: String?, pcpid: String?, promoCode: String?, label: String?) {
        self.type = type
        self.pcpid = pcpid
        self.promoCode = promoCode
        self.label = label
    }
}

@objcMembers class NoticeAction: Object, Decodable {
    dynamic var type: String?
    dynamic var pcpid: String?
    dynamic var promoCode: String?
    dynamic var label: String?

    enum CodingKeys: String, CodingKey {
        case type
        case pcpid
        case promoCode = "promo_code"
        case label
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Realm-safe decoding
        setValue(try container.decodeIfPresent(String.self, forKey: .type), forKey: "type")
        setValue(try container.decodeIfPresent(String.self, forKey: .pcpid), forKey: "pcpid")
        setValue(try container.decodeIfPresent(String.self, forKey: .promoCode), forKey: "promoCode")
        setValue(try container.decodeIfPresent(String.self, forKey: .label), forKey: "label")
    }

    func getModel() -> NoticeActionModel {
        .init(from: self)
    }
}

struct NoticeModel {
    let id: Int
    let title: String
    let message: String
    let date: Int
    let popup: Bool
    let action: NoticeActionModel?

    init(id: Int,
         title: String,
         message: String,
         date: Int,
         popup: Bool,
         action: NoticeActionModel?) {
        self.id = id
        self.title = title
        self.message = message
        self.date = date
        self.popup = popup
        self.action = action
    }

    init(from: Notice) {
        self.id = from.id
        self.title = from.title
        self.message = from.message
        self.date = from.date
        self.popup = from.popup
        self.action = from.action?.getModel()
    }
}

@objcMembers class Notice: Object, Decodable {
    dynamic var id: Int = 0
    dynamic var title: String = ""
    dynamic var message: String = ""
    dynamic var date: Int = 0
    dynamic var popup: Bool = false
    dynamic var permFree: Bool = false
    dynamic var permPro: Bool = false
    dynamic var action: NoticeAction?

    enum CodingKeys: String, CodingKey {
        case id, title, message, date, popup
        case permFree = "perm_free"
        case permPro = "perm_pro"
        case action
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)

        setValue(try container.decode(Int.self, forKey: .id), forKey: "id")
        setValue(try container.decode(String.self, forKey: .title), forKey: "title")
        setValue(try container.decode(String.self, forKey: .message), forKey: "message")
        setValue(try container.decode(Int.self, forKey: .date), forKey: "date")
        setValue(try container.decodeIfPresent(Int.self, forKey: .popup) == 1, forKey: "popup")
        setValue(try container.decodeIfPresent(Int.self, forKey: .permPro) == 1, forKey: "permPro")
        setValue(try container.decodeIfPresent(Int.self, forKey: .permFree) == 1, forKey: "permFree")

        if container.contains(.action) {
            let actionObj = try container.decodeIfPresent(NoticeAction.self, forKey: .action)
            setValue(actionObj, forKey: "action")
        } else {
            setValue(nil, forKey: "action")
        }
    }

    convenience init(from model: NoticeModel) {
        self.init()
        setValue(model.id, forKey: "id")
        setValue(model.title, forKey: "title")
        setValue(model.message, forKey: "message")
        setValue(model.date, forKey: "date")
        setValue(model.popup, forKey: "popup")
        if let actionModel = model.action {
            let actionObj = NoticeAction()
            actionObj.setValue(actionModel.type, forKey: "type")
            actionObj.setValue(actionModel.pcpid, forKey: "pcpid")
            actionObj.setValue(actionModel.promoCode, forKey: "promoCode")
            actionObj.setValue(actionModel.label, forKey: "label")
            setValue(actionObj, forKey: "action")
        } else {
            setValue(nil, forKey: "action")
        }
    }

    func getModel() -> NoticeModel {
        .init(from: self)
    }
}

struct NoticeList: Decodable {
    let notices: List<Notice>

    enum CodingKeys: String, CodingKey {
        case data
    }

    enum DataKeys: String, CodingKey {
        case notifications
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dataContainer = try container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        let array = try dataContainer.decode([Notice].self, forKey: .notifications)
        notices = List<Notice>()
        notices.append(objectsIn: array)
    }
}

/// This does not need a model, it's never used outside it's own imediate call.
@objcMembers class ReadNotice: Object {
    dynamic var id: Int = 0

    convenience init(noticeID: Int) {
        self.init()
        id = noticeID
    }

    override static func primaryKey() -> String? {
        return "id"
    }
}

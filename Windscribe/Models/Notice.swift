//
//  Notice.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-14.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct NoticeModel {
    let id: Int?
    let title: String?
    let message: String?
    let date: Int?
    let popup: Bool?
    let action: NoticeAction?

    init(id: Int,
         title: String,
         message: String,
         date: Int,
         popup: Bool,
         action: NoticeAction?) {
        self.id = id
        self.title = title
        self.message = message
        self.date = date
        self.popup = popup
        self.action = action
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

    func getModel() -> NoticeModel {
        return NoticeModel(id: id,
                           title: title,
                           message: message,
                           date: date,
                           popup: popup,
                           action: action)
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

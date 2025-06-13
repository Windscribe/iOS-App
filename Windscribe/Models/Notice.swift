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
        case id
        case title
        case message
        case date
        case popup
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

        let decodedID = try container.decode(Int.self, forKey: .id)
        let decodedTitle = try container.decode(String.self, forKey: .title)
        let decodedMessage = try container.decode(String.self, forKey: .message)
        let decodedDate = try container.decode(Int.self, forKey: .date)
        let decodedPopup = try container.decodeIfPresent(Int.self, forKey: .popup) == 1
        let decodedPermPro = try container.decodeIfPresent(Int.self, forKey: .permPro) == 1
        let decodedPermFree = try container.decodeIfPresent(Int.self, forKey: .permFree) == 1
        let decodedAction = try container.decodeIfPresent(NoticeAction.self, forKey: .action)

        setValue(decodedID, forKey: "id")
        setValue(decodedTitle, forKey: "title")
        setValue(decodedMessage, forKey: "message")
        setValue(decodedDate, forKey: "date")
        setValue(decodedPopup, forKey: "popup")
        setValue(decodedPermPro, forKey: "permPro")
        setValue(decodedPermFree, forKey: "permFree")
        setValue(decodedAction, forKey: "action")
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
        type = try container.decodeIfPresent(String.self, forKey: .type)
        pcpid = try container.decodeIfPresent(String.self, forKey: .pcpid)
        promoCode = try container.decodeIfPresent(String.self, forKey: .promoCode)
        label = try container.decodeIfPresent(String.self, forKey: .label)
    }
}

struct NoticeList: Decodable {
    let notices: List<Notice>

    enum CodingKeys: String, CodingKey {
        case data
        case notifications
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        notices = List<Notice>()
        if let noticesArray = try data.decodeIfPresent([Notice].self, forKey: .notifications) {
            notices.append(objectsIn: noticesArray)
        }
    }
}

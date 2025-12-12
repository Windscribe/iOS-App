//
//  MobilePlan.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-14.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers class MobilePlan: Object, Decodable {
    dynamic var active: Bool = false
    dynamic var extId: String = ""
    dynamic var name: String = ""
    dynamic var price: String = ""
    dynamic var type: String = ""
    dynamic var duration: Int = 0
    dynamic var discount: Int = 0

    enum CodingKeys: String, CodingKey {
        case active
        case extId = "ext_id"
        case name
        case price
        case type
        case wsPlanId = "ws_plan_id"
        case discount
        case duration
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        active = try container.decodeIfPresent(Int.self, forKey: .active) == 1 ? true : false
        extId = try container.decodeIfPresent(String.self, forKey: .extId) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        price = try container.decodeIfPresent(String.self, forKey: .price) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 0
        discount = try container.decodeIfPresent(Int.self, forKey: .discount) ?? -1
    }

    convenience init(from: MobilePlanModel) {
        self.init()
        active = from.active
        extId = from.extId
        name = from.name
        price = from.price
        type = from.type
        duration = from.duration
        discount = from.discount
    }

    override class func primaryKey() -> String? {
        return "extId"
    }
}

struct MobilePlanList: Decodable {
    let mobilePlans = List<MobilePlan>()

    enum CodingKeys: String, CodingKey {
        case data
        case plans
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        if let mobilePlansArray = try data.decodeIfPresent([MobilePlan].self, forKey: .plans) {
            setMobilePlans(array: mobilePlansArray)
        }
    }

    func setMobilePlans(array: [MobilePlan]) {
        mobilePlans.removeAll()
        mobilePlans.append(objectsIn: array)
    }
}


struct MobilePlanModel: Equatable {
    var active: Bool = false
    var extId: String = ""
    var name: String = ""
    var price: String = ""
    var type: String = ""
    var duration: Int = 0
    var discount: Int = 0

    init(from: MobilePlan) {
        active = from.active
        extId = from.extId
        name = from.name
        price = from.price
        type = from.type
        duration = from.duration
        discount = from.discount
    }
}

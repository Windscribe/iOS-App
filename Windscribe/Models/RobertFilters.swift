//
//  RobertSettings.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-12-17.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers class RobertFilters: Object, Decodable {

    dynamic var filters: List<RobertFilter> = List()
    dynamic var id: String = "1"

    enum CodingKeys: String, CodingKey {
        case data
        case filters
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        filters = try data.decodeIfPresent(List<RobertFilter>.self, forKey: .filters) ?? List()
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    func getRules() -> [RobertFilter] {
        var filterArray = [RobertFilter]()
        filters.forEach {  filter in
            filterArray.append(filter)
        }
        return filterArray
    }
}

@objcMembers class RobertFilter: Object, Decodable {

    dynamic var title: String = ""
    dynamic var filterDescription: String = ""
    dynamic var id: String = ""
    dynamic var status: Int = 0
    dynamic var enabled: Bool = false

    enum CodingKeys: String, CodingKey {
        case title = "title"
        case filterDescription = "description"
        case id = "id"
        case status = "status"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        filterDescription = try container.decodeIfPresent(String.self, forKey: .filterDescription) ?? ""
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        status = try container.decodeIfPresent(Int.self, forKey: .status) ?? 0
        if status == 1 {
            enabled = true
        } else {
            enabled = false
        }
    }
}

//
//  RobertFilters.swift
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

    convenience init(from models: [RobertFilterModel]) {
        self.init()
        let realmFilters = models.map { model -> RobertFilter in
            let f = RobertFilter()
            f.id = model.id
            f.title = model.title
            f.filterDescription = model.filterDescription
            f.status = model.status
            f.enabled = model.enabled
            return f
        }
        filters.removeAll()
        filters.append(objectsIn: realmFilters)
    }

    override static func primaryKey() -> String? {
        return "id"
    }
}

@objcMembers class RobertFilter: Object, Decodable {
    dynamic var title: String = ""
    dynamic var filterDescription: String = ""
    dynamic var id: String = ""
    dynamic var status: Int = 0
    dynamic var enabled: Bool = false

    enum CodingKeys: String, CodingKey {
        case title
        case filterDescription = "description"
        case id
        case status
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

    func getModel() -> RobertFilterModel {
        .init(from: self)
    }
}

struct RobertFilterModel: Equatable, Hashable, Codable {
    var id: String
    var title: String
    var filterDescription: String
    var status: Int
    let enabled: Bool

    init(from: RobertFilter) {
        id = from.id
        title = from.title
        filterDescription = from.filterDescription
        status = from.status
        enabled = from.enabled
    }

    init(id: String, title: String, filterDescription: String, status: Int, enabled: Bool) {
        self.id = id
        self.title = title
        self.filterDescription = filterDescription
        self.status = status
        self.enabled = enabled
    }
}

//
//  LocationModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct LocationsListModel: Decodable {
    let locations: [LocationModel]

    enum CodingKeys: String, CodingKey {
        case data
        case locations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        locations = try data.decodeIfPresent([LocationModel].self, forKey: .locations) ?? []
    }

    init(locations: [LocationModel]) {
        self.locations = locations
    }
}

struct LocationModel: Decodable, Equatable, Sendable {
    let id: Int
    let name: String
    let countryCode: String
    let shortName: String
    let sortOrder: Int
    let continent: String
    var datacenters: [DatacenterModel]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case countryCode = "country_code"
        case shortName = "short_name"
        case sortOrder = "sort_order"
        case continent
        case datacenters
    }

    var isPremiumOnly: Bool {
        datacenters.first { !$0.isPremiumOnly } == nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? -1
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode) ?? ""
        shortName = try container.decodeIfPresent(String.self, forKey: .shortName) ?? ""
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        continent = try container.decodeIfPresent(String.self, forKey: .continent) ?? ""
        datacenters = try container.decodeIfPresent([DatacenterModel].self, forKey: .datacenters) ?? []

        mapDatacenters()
    }

    init(id: Int,
         name: String,
         countryCode: String,
         shortName: String,
         sortOrder: Int,
         continent: String,
         datacenters: [DatacenterModel]) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.shortName = shortName
        self.sortOrder = sortOrder
        self.continent = continent
        self.datacenters = datacenters

        mapDatacenters()
    }

    init(from object: LocationObject) {
        self.id = object.id
        self.name = object.name
        self.countryCode = object.countryCode
        self.shortName = object.shortName
        self.sortOrder = object.sortOrder
        self.continent = object.continent
        self.datacenters = object.datacenters.map { DatacenterModel(from: $0) }

        mapDatacenters()
    }

    private mutating func mapDatacenters() {
        datacenters = datacenters.map {
            var updatedDatacenter = $0
            updatedDatacenter.locationId = id
            return updatedDatacenter
        }
    }

    func copyModelWith(datacenters: [DatacenterModel]) -> LocationModel {
        return  LocationModel(id: self.id,
                              name: self.name,
                              countryCode: self.countryCode,
                              shortName: self.shortName,
                              sortOrder: self.sortOrder,
                              continent: continent,
                              datacenters: datacenters)
    }

    func getServerNetLoad() -> Int {
        guard !datacenters.isEmpty else { return 0 }
        let totalNetLoad = datacenters.filter {
            $0.netLoad > 0
        }.reduce(0) { x, y in
            x + y.netLoad
        }
        if totalNetLoad > 0 {
            let numberOfDatacenters = datacenters.filter { $0.netLoad > 0 }.count
            return totalNetLoad / numberOfDatacenters
        }
        return 0
    }

    func getCustomLocation(withName newName: String, andDatacenters newDatacenters: [DatacenterModel]) -> LocationModel {
        LocationModel(id: id,
                      name: newName,
                      countryCode: countryCode,
                      shortName: shortName,
                      sortOrder: sortOrder,
                      continent: continent,
                      datacenters: newDatacenters)
    }

    func getBestLocationModel() -> LocationModel {
        LocationModel(id: id,
                      name: Fields.Values.bestLocation,
                      countryCode: countryCode,
                      shortName: shortName,
                      sortOrder: sortOrder,
                      continent: continent,
                      datacenters: datacenters)
    }
}

@objcMembers class LocationObject: Object {
    dynamic var id: Int = 0
    dynamic var name: String = ""
    dynamic var countryCode: String = ""
    dynamic var shortName: String = ""
    dynamic var sortOrder: Int = 0
    dynamic var continent: String = ""
    var datacenters = List<DatacenterObject>()

    override static func primaryKey() -> String? {
        return "id"
    }

    convenience init(from model: LocationModel) {
        self.init()
        self.id = model.id
        self.name = model.name
        self.countryCode = model.countryCode
        self.shortName = model.shortName
        self.sortOrder = model.sortOrder
        self.continent = model.continent
        self.datacenters.append(objectsIn: model.datacenters.map { DatacenterObject(from: $0) })
    }
}

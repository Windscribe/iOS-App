//
//  Extension.swift
//  Windscribe
//
//  Created by Andre Fonseca on 17/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

extension ExportedRegion {
    init(model: LocationModel) {
        id = model.id
        country = model.name
        cities = model.datacenters.map {
            ExportedCity(model: $0)
        }
    }
}

extension ExportedCity {
    init(model: DatacenterModel) {
        id = model.id
        name = model.city
        nickname =  model.nick
    }
}

//
//  Extension.swift
//  Windscribe
//
//  Created by Andre Fonseca on 17/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

extension ExportedRegion {
    init(model: ServerModel) {
        id = model.id
        country = model.name
        cities = model.groups.map {
            ExportedCity(model: $0)
        }
    }
}

extension ExportedCity {
    init(model: GroupModel) {
        id = model.id
        name = model.city
        nickname =  model.nick
    }
}

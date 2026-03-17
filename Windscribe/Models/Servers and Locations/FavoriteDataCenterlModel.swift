//
//  FavoriteDatacenterlModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 03/03/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct FavoriteDatacenterlModel {
    var pinnedIp: String?
    var pinnedNodeIp: String?
    var datacenterModel: DatacenterModel

    init(favourite: FavouriteModel, datacenterModel: DatacenterModel) {
        self.pinnedIp = favourite.pinnedIp
        self.pinnedNodeIp = favourite.pinnedNodeIp
        self.datacenterModel = datacenterModel
    }
}

@objcMembers class Favourite: Object, Decodable {
    @Persisted(primaryKey: true) var id: String
    @Persisted var pinnedIp: String?
    @Persisted var pinnedNodeIp: String?

    convenience init(id: String,
                     pinnedIp: String? = nil,
                     pinnedNodeIp: String? = nil) {
        self.init()
        self.id = id
        self.pinnedIp = pinnedIp
        self.pinnedNodeIp = pinnedNodeIp
    }

    convenience init(from: FavouriteModel) {
        self.init()
        self.id = from.id
        self.pinnedIp = from.pinnedIp
        self.pinnedNodeIp = from.pinnedNodeIp
    }

    func getModel() -> FavouriteModel {
        .init(from: self)
    }
}

struct FavouriteModel: Equatable {
    let id: String
    let pinnedIp: String?
    let pinnedNodeIp: String?

    init(from: Favourite) {
        self.id = from.id
        self.pinnedIp = from.pinnedIp
        self.pinnedNodeIp = from.pinnedNodeIp
    }

    init(id: String,
         pinnedIp: String? = nil,
         pinnedNodeIp: String? = nil) {
        self.id = id
        self.pinnedIp = pinnedIp
        self.pinnedNodeIp = pinnedNodeIp
    }

    func getObject() -> Favourite {
        .init(from: self)
    }
}

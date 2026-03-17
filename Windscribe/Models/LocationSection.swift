//
//  LocationSection.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-24.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation

struct LocationSection {
    var location: LocationModel?
    var collapsed: Bool

    init(location: LocationModel, collapsed: Bool) {
        self.location = location
        self.collapsed = collapsed
    }
}

struct IAPInfoSection {
    var title: String?
    var message: String?
    var collapsed: Bool

    init(title: String, message: String, collapsed: Bool) {
        self.title = title
        self.message = message
        self.collapsed = collapsed
    }
}

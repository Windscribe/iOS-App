//
//  Section.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-24.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RxDataSources

struct ServerSection {
    var server: ServerModel?
    var collapsed: Bool

    init(server: ServerModel,
         collapsed: Bool) {
        self.server = server
        self.collapsed = collapsed
    }
}

struct IAPInfoSection {
    var title: String?
    var message: String?
    var collapsed: Bool

    init(title: String,
         message: String,
         collapsed: Bool) {
        self.title = title
        self.message = message
        self.collapsed = collapsed
    }
}

//
//  HelpItem.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-06-24.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import UIKit
class HelpItem {
    var icon: String
    var title: String
    var subTitle: String
    var hideDivider: Bool

    init(icon: String = "",
         title: String,
         subTitle: String="",
         hideDivider: Bool = false) {
        self.icon = icon
        self.title = title
        self.subTitle = subTitle
        self.hideDivider = hideDivider
    }
}

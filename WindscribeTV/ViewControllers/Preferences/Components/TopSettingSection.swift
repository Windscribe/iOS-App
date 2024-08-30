//
//  TopSettingSection.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 30/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

class TopSettingSection: SettingsSection {
    override func populate(with list: [String], title: String? = nil) {
        super.populate(with: list, title: title)
        contentViewTop.constant = 0
        layoutIfNeeded()
    }
}

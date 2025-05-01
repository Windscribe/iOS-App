//
//  LocalizationBridge.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-01.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

struct LocalizationBridge {
    static var current: LocalizationService!

    static func setup(_ service: LocalizationService) {
        current = service
    }
}

extension String {
    var localized: String {
        LocalizationBridge.current.localizedString(for: self, comment: "")
    }

    func localized(comment: String = "") -> String {
        LocalizationBridge.current.localizedString(for: self, comment: comment)
    }
}

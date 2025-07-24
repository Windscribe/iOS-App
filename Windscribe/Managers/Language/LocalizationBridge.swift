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
        guard let service = LocalizationBridge.current else {
            // Fallback for network extensions where LocalizationBridge may not be initialized
            return self
        }
        return service.localizedString(for: self, comment: "")
    }

    func localized(comment: String = "") -> String {
        guard let service = LocalizationBridge.current else {
            // Fallback for network extensions where LocalizationBridge may not be initialized
            return self
        }
        return service.localizedString(for: self, comment: comment)
    }
}

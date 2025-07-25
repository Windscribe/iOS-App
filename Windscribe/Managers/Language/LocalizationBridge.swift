//
//  LocalizationBridge.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-01.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

struct LocalizationBridge {
    /// Emergency fallback localization service that just returns the key if an extension has not initialized the LocalizationBridge
    /// The PacketTunnelProvider used to have this issue before this protects against other possible cases
    private class EmptyLocalizationService: LocalizationService {
        func updateLanguage(_ language: Languages) { }

        func localizedString(for key: String, comment: String) -> String {
            key
        }
    }

    private static var _current: LocalizationService?
    private static let queue = DispatchQueue(label: "localization-bridge", attributes: .concurrent)

    private static var emptyService = EmptyLocalizationService()

    static var service: LocalizationService {
        return  queue.sync { _current ?? emptyService }
    }

    static var needsSetup: Bool {
        return queue.sync { _current == nil }
    }

    static func setup(_ service: LocalizationService) {
        queue.sync(flags: .barrier) {
            _current = service
        }
    }
}

extension String {
    var localized: String {
        return LocalizationBridge.service.localizedString(for: self, comment: "")
    }

    func localized(comment: String = "") -> String {
        return LocalizationBridge.service.localizedString(for: self, comment: comment)
    }
}

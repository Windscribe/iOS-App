//
//  DNSSettingsManaging.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import UIKit

/// DNS validation and resolution surface for Connection settings.
protocol DNSSettingsManaging: Sendable {
    /// Validates and parses DNS value from user input.
    /// - Parameters:
    ///   - value: The DNS string to validate (IP, DoH URL, or DoT hostname)
    ///   - completionDNS: Called with parsed DNSValue if valid
    ///   - completion: Called with boolean indicating if format is valid
    func getDNSValue(
        from value: String,
        completionDNS: @escaping @Sendable (DNSValue?) -> Void,
        completion: @escaping @Sendable (Bool) -> Void
    )
}

/// Adapter wrapping the legacy `DNSSettingsManager`.
final class LegacyDNSSettingsManager: DNSSettingsManaging, Sendable {
    private let legacy: DNSSettingsManagerType

    init(legacy: DNSSettingsManagerType) {
        self.legacy = legacy
    }

    func getDNSValue(
        from value: String,
        completionDNS: @escaping @Sendable (DNSValue?) -> Void,
        completion: @escaping @Sendable (Bool) -> Void
    ) {
        legacy.getDNSValue(
            from: value,
            opensURL: UIApplication.shared,
            completionDNS: completionDNS,
            completion: completion
        )
    }
}

//
//  ReferAndSharing.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-10.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Referral/share state surface for Neo features.
protocol ReferAndSharing: Sendable {
    func setShowedShareDialog(showed: Bool)
}

/// Adapter wrapping the legacy `ReferAndShareManager`.
final class LegacyReferAndShareManager: ReferAndSharing, Sendable {
    private let legacy: ReferAndShareManager

    init(legacy: ReferAndShareManager) {
        self.legacy = legacy
    }

    func setShowedShareDialog(showed: Bool) {
        legacy.setShowedShareDialog(showed: showed)
    }
}

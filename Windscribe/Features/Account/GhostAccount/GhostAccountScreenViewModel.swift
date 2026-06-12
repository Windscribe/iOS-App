//
//  GhostAccountScreenViewModel.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-09.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Observation

@available(iOS 17.0, *)
@Observable
@MainActor
final class GhostAccountScreenViewModel {

    // MARK: - State (read by the view)
    var isUserPro: Bool

    private var hasStarted = false

    // MARK: - Dependencies (injected via init — protocols only)
    private let hapticFeedback: any HapticFeedbacking
    private let sessionProvider: any SessionProviding

    // MARK: - Init
    init(hapticFeedback: any HapticFeedbacking,
         sessionProvider: any SessionProviding) {
        self.hapticFeedback = hapticFeedback
        self.sessionProvider = sessionProvider
        self.isUserPro = sessionProvider.session?.isUserPro ?? false
    }

    // MARK: - Lifecycle

    func startObservers() async {
        guard !hasStarted else { return }
        hasStarted = true

        async let session: () = observeSession()

        _ = await (session)
    }

    func observeSession() async {
        for await session in sessionProvider.sessionUpdates {
            isUserPro = session?.isUserPro ?? false
        }
    }

    // MARK: - Actions (called by the view)

    func actionSelected() {
        hapticFeedback.run(level: .medium)
    }
}

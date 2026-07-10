//
//  ConfirmEmailScreenViewModel.swift
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
final class ConfirmEmailScreenViewModel {

    // MARK: - State (read by the view)

    var session: SessionModel?
    var resendButtonDisabled = false
    var showingResendSuccessAlert = false
    var shouldDismiss = false

    private var isObserving = false

    // MARK: - Dependencies (injected via init — protocols only)
    private let sessionProvider: any SessionProviding
    private let accountManager: any AccountManaging

    // MARK: - Init

    init(sessionProvider: any SessionProviding,
         accountManager: any AccountManaging) {
        self.sessionProvider = sessionProvider
        self.accountManager = accountManager
        self.session = sessionProvider.session
    }

    // MARK: - Lifecycle

    func startObservers() async {
        guard !isObserving else { return }
        isObserving = true
        defer { isObserving = false }

        async let session: () = observeSession()

        _ = await (session)
    }

    func observeSession() async {
        for await session in sessionProvider.sessionUpdates {
            self.session = session
            if session?.emailStatus == true {
                shouldDismiss = true
            }
        }
    }

    // MARK: - Actions (called by the view)

    func updateSession() {
        accountManager.keepSessionUpdated()
    }

    func resendEmail() {
        resendButtonDisabled = true

        Task {
            do {
                try await accountManager.resendConfirmationEmail()
                showingResendSuccessAlert = true
            } catch {
                resendButtonDisabled = false
            }
        }
    }

    func closeSelected() {
        updateSession()
        shouldDismiss = true
    }
}

//
//  EnterEmailFeatureViewModel.swift
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
final class EnterEmailFeatureViewModel {

    // MARK: - State (read by the view)

    var email: String
    var showLoading = false
    var currentError: String?
    var didSubmitEmail = false

    let emailInfoText = TextsAsset.get10GbAMonth
    let infoLabelText = TextsAsset.addEmailInfo
    let titleText = TextsAsset.addEmail

    private var shouldShowEmailPromo: Bool
    private var isObserving = false

    var emailIsValid: Bool {
        email.count > 3 && email.contains("@") && email.contains(".")
    }

    var showGet10GBPromo: Bool {
        shouldShowEmailPromo
    }

    // MARK: - Dependencies (injected via init — protocols only)

    private let sessionProvider: any SessionProviding
    private let accountManager: any AccountManaging

    // MARK: - Init

    init(sessionProvider: any SessionProviding,
         accountManager: any AccountManaging) {
        self.sessionProvider = sessionProvider
        self.accountManager = accountManager
        self.email = sessionProvider.session?.email ?? ""
        self.shouldShowEmailPromo = sessionProvider.session?.shouldShowEmailPromo ?? false
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
            shouldShowEmailPromo = session?.shouldShowEmailPromo ?? false
        }
    }

    // MARK: - Actions (called by the view)

    func submit() {
        guard emailIsValid else { return }

        showLoading = true
        currentError = nil

        Task {
            do {
                try await accountManager.addEmail(email)
                accountManager.keepSessionUpdated()
                didSubmitEmail = true
                showLoading = false
            } catch {
                currentError = EmailError.from(error).errorDescription
                showLoading = false
            }
        }
    }
}

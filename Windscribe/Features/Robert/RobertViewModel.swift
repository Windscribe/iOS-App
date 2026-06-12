//
//  RobertViewModel.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-04.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Observation

@available(iOS 17.0, *)
@Observable
@MainActor
final class RobertViewModel {

    // MARK: - State (read by the view)

    var isLoading = false
    var safariURL: URL?
    var errorMessage: String?
    var entries: [RobertFilterModel]
    let customRulesEntry: RobertEntryType = .customRules

    private var hasStarted = false

    // MARK: - Dependencies (injected via init — protocols only)

    private let hapticFeedback: any HapticFeedbacking
    private let filters: any RobertFiltering
    private let ruleURLProvider: any RobertRuleURLProviding
    private let logger: any LogStoring

    // MARK: - Init

    init(hapticFeedback: any HapticFeedbacking,
         filters: any RobertFiltering,
         ruleURLProvider: any RobertRuleURLProviding,
         logger: any LogStoring) {
        self.hapticFeedback = hapticFeedback
        self.filters = filters
        self.ruleURLProvider = ruleURLProvider
        self.logger = logger
        self.entries = filters.filters
    }

    // MARK: - Lifecycle

    func startObservers() async {
        guard !hasStarted else { return }
        hasStarted = true

        async let filterUpdates: () = observeFilters()
        async let refresh: () = refreshFilters()

        _ = await (filterUpdates, refresh)
    }

    func observeFilters() async {
        for await filterModels in filters.filterUpdates {
            entries = filterModels
        }
    }

    func refreshFilters() async {
        do {
            try await filters.refreshFilters()
        } catch {
            handleRefreshError(error)
        }
    }

    // MARK: - Actions (called by the view)

    func filterSelected(_ filter: RobertFilterModel) {
        hapticFeedback.run(level: .medium)
        isLoading = true

        Task {
            do {
                try await filters.updateFilter(filter)
            } catch {
                if let error = error as? RobertFilterErrors {
                    switch error {
                    case .failedSync(let message), .failedUpdate(let message):
                        errorMessage = message
                    }
                }
            }
            isLoading = false
        }
    }

    func infoSelected() {
        safariURL = URL(string: LinkProvider.getWindscribeLink(path: Links.learMoreAboutRobert))
    }

    func customRulesSelected() {
        hapticFeedback.run(level: .medium)
        logger.logI("RobertViewModel", "User tapped custom rules button.")

        Task {
            do {
                safariURL = try await ruleURLProvider.customRulesURL()
            } catch {
                handleCustomRulesError(error)
            }
        }
    }

    // MARK: - Private helpers

    private func handleRefreshError(_ error: Error) {
        if let error = error as? Errors {
            let newError: String
            switch error {
            case let .apiError(e):
                newError = e.errorMessage ?? TextsAsset.Robert.failedToGetFilters
            default:
                newError = "\(TextsAsset.Robert.failedToGetFilters) \(error.description)"
            }
            logger.logE("RobertViewModel", newError)
            errorMessage = newError
        }
    }

    private func handleCustomRulesError(_ error: Error) {
        if let error = error as? Errors {
            let newError: String
            switch error {
            case let .apiError(e):
                newError = e.errorMessage ?? "Failed to update Robert Session for custom rules."
            default:
                newError = "Failed to update Robert Session for custom rules. \(error.description)"
            }
            logger.logE("RobertViewModel", newError)
            errorMessage = newError
        }
    }
}

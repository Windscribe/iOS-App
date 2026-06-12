//
//  ViewLogScreenViewModel.swift
//  Windscribe
//
//  Created by Claude on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

@available(iOS 17.0, *)
@Observable
@MainActor
final class ViewLogScreenViewModel {
    // MARK: - Dependencies
    private let logger: any LogStoring

    // MARK: - State
    var logContent: String = ""
    var showProgress: Bool = false
    var fontSize: CGFloat = 10
    var showShareSheet: Bool = false
    private var hasLoaded = false

    init(logger: any LogStoring) {
        self.logger = logger
    }

    // MARK: - Actions
    func loadLog() {
        guard !hasLoaded else { return }
        hasLoaded = true

        showProgress = true

        Task {
            do {
                let content = try await logger.getLogData()
                self.logContent = content
                self.showProgress = false
            } catch {
                self.showProgress = false
            }
        }
    }

    func shareLog() {
        self.showShareSheet = true
    }
}

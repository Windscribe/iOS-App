//
//  RestrictiveNetworkScreenViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-07-01.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

@available(iOS 17.0, *)
@Observable
@MainActor
final class RestrictiveNetworkScreenViewModel {

    // MARK: - State
    var shouldDismiss = false
    var isExportingLogs = false
    var safariURL: URL?
    var showShareSheet = false
    var logContentToShare = ""

    // MARK: - Dependencies
    private let logger: LogStoring

    // MARK: - Initialization
    init(logger: LogStoring) {
        self.logger = logger
    }

    // MARK: - Actions
    func exportLogs() {
        logger.logI("RestrictiveNetworkScreenViewModel", "Starting log export...")
        isExportingLogs = true

        Task {
            do {
                let logContent = try await logger.getLogData()
                isExportingLogs = false
                logContentToShare = logContent
                showShareSheet = true
            } catch {
                isExportingLogs = false
                logger.logE("RestrictiveNetworkScreenViewModel", "Failed to export logs: \(error)")
            }
        }
    }

    func contactSupport() {
        logger.logI("RestrictiveNetworkScreenViewModel", "Opening contact support page.")
        safariURL = URL(string: Links.contactSupport)
    }

    func cancel() {
        shouldDismiss = true
    }
}

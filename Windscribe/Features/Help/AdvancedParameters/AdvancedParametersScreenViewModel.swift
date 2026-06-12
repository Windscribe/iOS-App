//
//  AdvancedParametersScreenViewModel.swift
//  Windscribe
//
//  Created by Claude on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

enum AdvanceParamsError: Error {
    case invalidKeyValuePair
}

@available(iOS 17.0, *)
@Observable
@MainActor
final class AdvancedParametersScreenViewModel {
    // MARK: - Dependencies
    private let preferencesReading: any PreferencesReading
    private let preferencesWriting: any PreferencesWriting

    // MARK: - State
    var advanceParams: String = ""
    var showProgressBar: Bool = false
    var showError: Bool = false

    init(
        preferencesReading: any PreferencesReading,
        preferencesWriting: any PreferencesWriting
    ) {
        self.preferencesReading = preferencesReading
        self.preferencesWriting = preferencesWriting

        // Load initial params
        self.advanceParams = preferencesReading.advanceParams ?? ""
    }

    // MARK: - Actions
    func onAdvanceParamsTextChange(text: String) {
        showError = false
        advanceParams = text
    }

    func saveButtonTap() {
        showProgressBar = true

        Task {
            do {
                // Validate the format
                try validateAdvanceParams(advanceParams)

                // Small delay for UX
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                // Save to preferences
                preferencesWriting.saveAdvanceParams(params: advanceParams)

                // Reload from preferences
                self.advanceParams = preferencesReading.advanceParams ?? ""
                self.showProgressBar = false
            } catch {
                self.showProgressBar = false
                if error is AdvanceParamsError {
                    self.showError = true
                }
            }
        }
    }

    // MARK: - Private Methods
    private func validateAdvanceParams(_ params: String) throws {
        let lines = params.split(separator: "\n")

        for line in lines {
            let components = line.split(separator: "=")
            if components.count != 2 {
                throw AdvanceParamsError.invalidKeyValuePair
            }
        }
    }
}

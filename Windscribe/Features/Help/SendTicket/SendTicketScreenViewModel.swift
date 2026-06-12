//
//  SendTicketScreenViewModel.swift
//  Windscribe
//
//  Created by Claude on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 17.0, *)
@Observable
@MainActor
final class SendTicketScreenViewModel {
    // MARK: - Dependencies
    private let sessionProviding: any SessionProviding
    private let ticketManaging: any TicketManaging

    // MARK: - State
    var email: String = ""
    var subject: String = ""
    var message: String = ""
    var category: String = TextsAsset.SubmitTicket.categories.first ?? ""

    var showProgress: Bool = false
    var showSuccess: Bool = false
    var showError: Bool = false
    var errorMessage: String = ""

    // MARK: - Computed Properties
    var isFormValid: Bool {
        email.isValidEmail() && !subject.isEmpty && !message.isEmpty
    }

    init(
        sessionProviding: any SessionProviding,
        ticketManaging: any TicketManaging
    ) {
        self.sessionProviding = sessionProviding
        self.ticketManaging = ticketManaging

        // Initialize email from session if available
        if let userEmail = sessionProviding.session?.email {
            self.email = userEmail
        }
    }

    // MARK: - Actions
    func sendTicket() {
        guard let categoryIndex = TextsAsset.SubmitTicket.categories.firstIndex(of: category) else {
            return
        }

        showProgress = true
        showSuccess = false
        showError = false

        let device = UIDevice.current
        let platform = "Brand: Apple | OS: \(device.systemVersion) | Model: \(UIDevice.modelName)"
        let name = sessionProviding.session?.userId ?? ""

        Task {
            do {
                _ = try await ticketManaging.sendTicket(
                    email: email,
                    name: name,
                    subject: subject,
                    message: message,
                    category: "\(categoryIndex + 1)",
                    type: category,
                    channel: "app_ios",
                    platform: platform
                )

                self.showProgress = false
                self.showSuccess = true
            } catch {
                self.showProgress = false
                self.errorMessage = error.localizedDescription.isEmpty
                    ? TextsAsset.SubmitTicket.failedToSendTicket
                    : error.localizedDescription
                self.showError = true
            }
        }
    }
}

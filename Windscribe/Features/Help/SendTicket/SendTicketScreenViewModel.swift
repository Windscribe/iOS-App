//
//  SendTicketScreenViewModel.swift
//  Windscribe
//
//  Created by Claude on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

@available(iOS 17.0, *)
@Observable
@MainActor
final class SendTicketScreenViewModel {
    // MARK: - State
    var email: String = ""
    var subject: String = ""
    var message: String = ""
    var category: String = TextsAsset.SubmitTicket.categories.first ?? ""

    var showError: Bool = false
    var errorMessage: String = ""
    var safariURL: URL?
    var showingSafari: Bool = false

    // MARK: - Computed Properties
    var isFormValid: Bool {
        email.isValidEmail() && !subject.isEmpty && !message.isEmpty
    }

    init(sessionProviding: any SessionProviding) {
        // Initialize email from session if available
        if let userEmail = sessionProviding.session?.email {
            self.email = userEmail
        }
    }

    // MARK: - Actions
    func sendTicket() {
        let supportText = [subject, message]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        guard let url = LinkProvider.getKnowledgeBaseGarryURL(message: supportText) else {
            errorMessage = TextsAsset.SubmitTicket.failedToSendTicket
            showError = true
            return
        }

        showError = false
        safariURL = url
        showingSafari = true
    }
}

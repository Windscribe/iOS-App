//
//  TicketManaging.swift
//  Windscribe
//
//  Created by Claude on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Support ticket submission surface.
protocol TicketManaging: Sendable {
    /// Sends a support ticket to the server.
    /// - Parameters:
    ///   - email: User's email address
    ///   - name: User's name/ID
    ///   - subject: Ticket subject
    ///   - message: Ticket message content
    ///   - category: Category index as string
    ///   - type: Category type description
    ///   - channel: App channel identifier
    ///   - platform: Device platform information
    /// - Returns: APIMessage response
    func sendTicket(
        email: String,
        name: String,
        subject: String,
        message: String,
        category: String,
        type: String,
        channel: String,
        platform: String
    ) async throws -> APIMessage
}

/// Adapter wrapping the legacy `APIManager`.
final class LegacyTicketManager: TicketManaging, Sendable {
    private let legacy: APIManager

    init(legacy: APIManager) {
        self.legacy = legacy
    }

    func sendTicket(
        email: String,
        name: String,
        subject: String,
        message: String,
        category: String,
        type: String,
        channel: String,
        platform: String
    ) async throws -> APIMessage {
        try await legacy.sendTicket(
            email: email,
            name: name,
            subject: subject,
            message: message,
            category: category,
            type: type,
            channel: channel,
            platform: platform
        )
    }
}

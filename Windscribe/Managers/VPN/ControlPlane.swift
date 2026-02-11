//
//  ControlPlane.swift
//  WireGuardTunnel
//
//  Created by Ginder Singh on 2026-02-11.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import os

/// Control plane that monitors VPN tunnel health and user session validity.
/// Started when tunnel is ready and works with packet tunnel provider.
class ControlPlane {

    private let consoleLogger: Logger
    private let apiUtil: APIUtilService
    private let api: WSNetServerAPI
    private let preferences: Preferences

    private var runningHealthCheck = false
    private weak var credentialsManager: TunnelCredentialsManaging?
    private weak var tunnelProvider: NEPacketTunnelProvider?

    init(
        apiUtil: APIUtilService,
        api: WSNetServerAPI,
        preferences: Preferences,
        credentialsManager: TunnelCredentialsManaging?,
        tunnelProvider: NEPacketTunnelProvider,
        consoleLogger: Logger
    ) {
        self.apiUtil = apiUtil
        self.api = api
        self.preferences = preferences
        self.credentialsManager = credentialsManager
        self.tunnelProvider = tunnelProvider
        self.consoleLogger = consoleLogger
    }

    /// Called from packet tunnel provider when tunnel health is not good (handshake fails, wake up, etc.)
    func checkTunnelHealth() {
        // Skip health check for custom configs
        guard !preferences.isCustomConfigSelected() else { return }
        guard !runningHealthCheck else { return }

        DispatchQueue.global().async { [weak self] in
            self?.performHealthCheck()
        }
    }

    /// Performs the actual health check by fetching session
    private func performHealthCheck() {
        runningHealthCheck = true
        consoleLogger.debug("Requesting user session update.")

        Task { [weak self] in
            guard let self = self else { return }
            defer { self.runningHealthCheck = false }

            do {
                let session = try await getSession()
                consoleLogger.debug("User session update successful. Status: \(session.status, privacy: .public)")

                if session.status != 1 {
                    consoleLogger.debug("Session status is \(session.status, privacy: .public) (not active), stopping tunnel.")
                    await stopTunnel(reason: .accountStatusChanged)
                    return
                }

                if session.isPremium != preferences.getUserStatus() {
                    await stopTunnel(reason: .userStatusChanged)
                    return
                }

                consoleLogger.debug("Health check passed.")
            } catch {
                consoleLogger.debug("Get Session failed. \(error, privacy: .public)")

                if let wsError = error as? Errors {
                    switch wsError {
                        case .sessionIsInvalid:
                            consoleLogger.debug("Session is invalid, stopping tunnel.")
                            await stopTunnel(reason: .invalidSession)

                        case let .apiError(apiError):
                            consoleLogger.debug("Get Session failed with API error - \(apiError.errorMessage ?? "unknown", privacy: .public)")

                        default:
                            consoleLogger.debug("Get Session failed with error: \(wsError.unlocalizedDescription, privacy: .public)")
                    }
                }
            }
        }
    }

    /// Stops the tunnel with error code 50 (credentials failure)
    private func stopTunnel(reason: DisconnectReason) async {
        consoleLogger.debug("Stopping tunnel - Reason: \(reason.rawValue, privacy: .public)")
        preferences.saveDisconnectReason(reason: reason)

        // Cancel tunnel with error code 50
        let error = NSError(domain: "com.windscribe", code: 50, userInfo: [
            NSLocalizedDescriptionKey: reason
        ])
        credentialsManager?.deleteCredentials(error: error)
    }

    func getSession() async throws -> Session {
        guard let sessionAuth = preferences.userSessionAuth() else {
            throw Errors.validationFailure
        }

        return try await apiUtil.makeApiCall(modalType: Session.self) { completion in
            self.api.session(sessionAuth, appleId: "", gpDeviceId: "", callback: completion)
        }
    }
}

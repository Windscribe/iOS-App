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
    private let logger: FileLogger
    private let apiUtil: APIUtilService
    private let api: WSNetServerAPI
    private let preferences: Preferences
    private let providerConfiguration: [String: Any]?
    private let onTunnelShouldStop: @MainActor (DisconnectReason, NSError) -> Void

    private var runningHealthCheck = false
    private var lastHealthCheckTime: TimeInterval = 0

    init(
        apiUtil: APIUtilService,
        api: WSNetServerAPI,
        preferences: Preferences,
        providerConfiguration: [String: Any]?,
        logger: FileLogger,
        consoleLogger: Logger,
        onTunnelShouldStop: @escaping @MainActor (DisconnectReason, NSError) -> Void
    ) {
        self.apiUtil = apiUtil
        self.api = api
        self.preferences = preferences
        self.providerConfiguration = providerConfiguration
        self.logger = logger
        self.consoleLogger = consoleLogger
        self.onTunnelShouldStop = onTunnelShouldStop
    }

    /// Called from packet tunnel provider when tunnel health is not good (handshake fails, wake up, etc.)
    func checkTunnelHealth() {
        // Skip health check for custom configs
        guard !preferences.isCustomConfigSelected() else { return }
        guard !runningHealthCheck else {
            consoleLogger.debug("Health check already running, skipping.")
            return
        }

        // Throttle health checks to once every 10 seconds
        let currentTime = Date().timeIntervalSince1970
        if lastHealthCheckTime > 0 && currentTime - lastHealthCheckTime < 10 {
            consoleLogger.debug("Health check throttled (last check was \(Int(currentTime - self.lastHealthCheckTime))s ago), skipping.")
            return
        }

        // Set flag BEFORE dispatching to prevent race condition
        runningHealthCheck = true
        lastHealthCheckTime = currentTime

        DispatchQueue.global().async { [weak self] in
            self?.performHealthCheck()
        }
    }

    /// Performs the actual health check by fetching session
    private func performHealthCheck() {
        consoleLogger.debug("Requesting user session update.")

        Task { [weak self] in
            guard let self = self else { return }
            defer { self.runningHealthCheck = false }

            do {
                let sessionModel = try await getSession()
                consoleLogger.debug("User session update successful. Status: \(sessionModel.status, privacy: .public)")

                if sessionModel.status != 1 {
                    consoleLogger.debug("Session status is \(sessionModel.status, privacy: .public) (not active), stopping tunnel.")
                    await stopTunnel(reason: .accountStatusChanged)
                    return
                }

                // Check if user status changed since connection started
                // isUserPro = isPremium || isUserUnlimited (billingPlanId == -9)
                // This catches transitions between Free/Pro/Unlimited tiers
                let connectionUserStatus = providerConfiguration?["isUserPro"] as? Bool ?? false
                if sessionModel.isUserPro != connectionUserStatus {
                    logger.logI("ControlPlane", "User status changed since connection: connection=\(connectionUserStatus), current=\(sessionModel.isUserPro)", flushImmediately: true)
                    consoleLogger.debug("User status changed: connection=\(connectionUserStatus), current=\(sessionModel.isUserPro)")
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

        // Call the callback on main thread to handle tunnel cancellation
        await onTunnelShouldStop(reason, error)
    }

    func getSession() async throws -> SessionModel {
        guard let sessionAuth = preferences.userSessionAuth() else {
            throw Errors.validationFailure
        }
        let revision = preferences.getServerRevision()
        let useBackup = preferences.getRoutingType().apiValue
        return try await apiUtil.makeApiCall(modalType: SessionModel.self) { completion in
            self.api.session(sessionAuth, appleId: "", gpDeviceId: "", invRev: revision, backup: useBackup, callback: completion)
        }
    }
}

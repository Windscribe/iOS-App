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
        onTunnelShouldStop: @escaping @MainActor (DisconnectReason, NSError) -> Void
    ) {
        self.apiUtil = apiUtil
        self.api = api
        self.preferences = preferences
        self.providerConfiguration = providerConfiguration
        self.logger = logger
        self.onTunnelShouldStop = onTunnelShouldStop
    }

    /// Called from packet tunnel provider when tunnel health is not good (handshake fails, wake up, etc.)
    func checkTunnelHealth() {
        // Skip health check for custom configs
        guard !preferences.isCustomConfigSelected() else { return }
        guard !runningHealthCheck else {
            logger.logD("ControlPlane", "Health check already running, skipping.")
            return
        }

        // Throttle health checks to once every 10 seconds
        let currentTime = Date().timeIntervalSince1970
        if lastHealthCheckTime > 0 && currentTime - lastHealthCheckTime < 10 {
            logger.logD("ControlPlane", "Health check throttled (last check was \(Int(currentTime - self.lastHealthCheckTime))s ago), skipping.")
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
        logger.logD("ControlPlane", "Requesting user session update.")

        Task { [weak self] in
            guard let self = self else { return }
            defer { self.runningHealthCheck = false }

            do {
                let sessionModel = try await getSession()
                let connectionUserStatus = providerConfiguration?["isUserPro"] as? Bool ?? false
                logger.logD("ControlPlane", "Session updated | status=\(sessionModel.status), isPro=\(connectionUserStatus)→\(sessionModel.isUserPro)")
                // Account status change
                if sessionModel.status != 1 {
                    logger.logI("ControlPlane", "Session status is \(sessionModel.status) (not active), stopping tunnel.", flushImmediately: true)
                    await stopTunnel(reason: .accountStatusChanged)
                    return
                }
                // Check if user status changed since connection started
                // isUserPro = isPremium || isUserUnlimited (billingPlanId == -9)
                // This catches transitions between Free/Pro/Unlimited tiers
                if sessionModel.isUserPro != connectionUserStatus {
                    await stopTunnel(reason: .userStatusChanged)
                    return
                }
            } catch {
                logger.logE("ControlPlane", "Get Session failed. \(error)")

                if let wsError = error as? Errors {
                    switch wsError {
                    case .sessionIsInvalid:
                        logger.logI("ControlPlane", "Session is invalid, stopping tunnel.", flushImmediately: true)
                        await stopTunnel(reason: .invalidSession)

                    case let .apiError(apiError):
                        logger.logE("ControlPlane", "Get Session failed with API error - \(apiError.errorMessage ?? "unknown")")

                    default:
                        logger.logE("ControlPlane", "Get Session failed with error: \(wsError.unlocalizedDescription)")
                    }
                }
            }
        }
    }

    /// Stops the tunnel with error code 50 (credentials failure)
    private func stopTunnel(reason: DisconnectReason) async {
        logger.logI("ControlPlane", "Stopping tunnel - Reason: \(reason.rawValue)", flushImmediately: true)
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

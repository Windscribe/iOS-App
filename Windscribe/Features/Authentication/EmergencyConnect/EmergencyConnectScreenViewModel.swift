//
//  EmergencyConnectScreenViewModel.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Observation

@available(iOS 17.0, *)
enum EmergencyConnectScreenState {
    case disconnected, disconnecting, connecting, connected
}

@available(iOS 17.0, *)
@Observable
@MainActor
final class EmergencyConnectScreenViewModel {

    // MARK: - State (read by the view)

    var connectionState: EmergencyConnectScreenState = .disconnected
    var isStagingAlertPresented = false

    // MARK: - Dependencies (injected via init — protocols only)

    private let vpnStateProviding: any VPNStateProviding
    private let emergencyConnecting: any EmergencyConnecting
    private let logger: any LogStoring

    private var isObserving = false

    // MARK: - Init

    init(
        vpnStateProviding: any VPNStateProviding,
        emergencyConnecting: any EmergencyConnecting,
        logger: any LogStoring
    ) {
        self.vpnStateProviding = vpnStateProviding
        self.emergencyConnecting = emergencyConnecting
        self.logger = logger
    }

    // MARK: - Lifecycle

    func startObservers() async {
        guard !isObserving else { return }
        isObserving = true
        defer { isObserving = false }

        async let vpnState: () = observeVPNStateChanges()

        _ = await (vpnState)
    }

    func appEnteredForeground() {
        vpnStateProviding.refreshConnectionState()
    }

    // MARK: - Actions (called by the view)

    func connectButtonTapped() {
        if Env.isStaging {
            isStagingAlertPresented = true
            return
        }

        guard connectionState != .disconnecting else { return }

        Task {
            if connectionState == .connected || connectionState == .connecting {
                logger.logD("EmergencyConnectViewModel", "Disconnecting from emergency connect.")
                try? await emergencyConnecting.disconnect()
            } else {
                logger.logD("EmergencyConnectViewModel", "Getting emergency connect configuration.")
                let config = await emergencyConnecting.getConfig()
                await connect(using: config)
            }
        }
    }

    // MARK: - Private helpers

    private func observeVPNStateChanges() async {
        for await state in vpnStateProviding.statusUpdates {
            logger.logI("EmergencyConnectViewModel", "VPN state changed to \(state)")

            switch state {
            case .connected:
                connectionState = .connected
            case .connecting:
                connectionState = .connecting
            case .disconnecting:
                connectionState = .disconnecting
            default:
                connectionState = .disconnected
            }
        }
    }

    private func connect(using ovpnInfoList: [OpenVPNConnectionInfo]) async {
        guard !ovpnInfoList.isEmpty else {
            logger.logE("EmergencyConnectViewModel", "Unable to get emergency connect configuration.")
            return
        }

        do {
            do {
                try await emergencyConnecting.connect(configInfo: ovpnInfoList[0])
            } catch {
                guard ovpnInfoList.count > 1 else { throw error }
                try await emergencyConnecting.connect(configInfo: ovpnInfoList[1])
            }

            logger.logI("EmergencyConnectViewModel", "Successfully started OpenVPN.")
        } catch {
            logger.logE("EmergencyConnectViewModel", "Failed to start OpenVPN: \(error.localizedDescription)")
            vpnStateProviding.resetToDisconnected()

            try? await emergencyConnecting.disconnect()
            logger.logD("EmergencyConnectViewModel", "Cleaned up after connection failure")
        }
    }
}

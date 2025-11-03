//
//  LivecycleManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 08/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import UIKit
import NetworkExtension

protocol LivecycleManagerType {
    var showNetworkSecurityTrigger: PassthroughSubject<Void, Never> { get }
    var showNotificationsTrigger: PassthroughSubject<Void, Never> { get }
    var becameActiveTrigger: PassthroughSubject<Void, Never> { get }

    func onAppStart()
    func appEnteredForeground()
}

class LivecycleManager: LivecycleManagerType {
    let logger: FileLogger
    let sessionManager: SessionManager
    let preferences: Preferences
    let vpnManager: VPNManager
    let connectivity: ConnectivityManager
    let credentialsRepo: CredentialsRepository
    let notificationRepo: NotificationRepository
    let ipRepository: IPRepository
    let configManager: ConfigurationsManager
    let connectivityManager: ProtocolManagerType
    let locationsManager: LocationsManager

    let showNetworkSecurityTrigger = PassthroughSubject<Void, Never>()
    let showNotificationsTrigger = PassthroughSubject<Void, Never>()
    let becameActiveTrigger = PassthroughSubject<Void, Never>()
    var disconnectTask: AnyCancellable?
    var connectTask: AnyCancellable?
    var testTask: Task<Void, Error>?

    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger,
         sessionManager: SessionManager,
         preferences: Preferences,
         vpnManager: VPNManager,
         connectivity: ConnectivityManager,
         credentialsRepo: CredentialsRepository,
         notificationRepo: NotificationRepository,
         ipRepository: IPRepository,
         configManager: ConfigurationsManager,
         connectivityManager: ProtocolManagerType,
         locationsManager: LocationsManager) {
        self.logger = logger
        self.sessionManager = sessionManager
        self.preferences = preferences
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.credentialsRepo = credentialsRepo
        self.notificationRepo = notificationRepo
        self.ipRepository = ipRepository
        self.configManager = configManager
        self.connectivityManager = connectivityManager
        self.locationsManager = locationsManager
    }

    /// Fresh app launch.
    func onAppStart() {
        Task {
            await notificationRepo.loadNotifications()
        }
    }

    private func checkForKillSwitch() {
        vpnManager.configureForConnectionState()
        let info = vpnManager.vpnInfo.value
        if connectivity.internetConnectionAvailable() {
            if info?.killSwitch == true && vpnManager.isDisconnected() && !WifiManager.shared.isConnectedWifiTrusted() {
                logger.logI("LivecycleManager", "VPN disocnnected, Turning off kill switch.")
                vpnManager.simpleDisableConnection()
            } else if vpnManager.isConnected() && testTask == nil {
                logger.logI("LivecycleManager", "VPN conencted. testing conenctivity.")
                testTask = testConnectivity()
            }
        }
    }

    /// App foreground.
    func appEnteredForeground() {
        checkForKillSwitch()
        logger.logI("LivecycleManager", "App internet moved to foreground.")
        becameActiveTrigger.send(())
        sessionManager.keepSessionUpdated()
        guard let lastNotificationTimestamp = preferences.getLastNotificationTimestamp() else {
            preferences.saveLastNotificationTimestamp(timeStamp: Date().timeIntervalSince1970)
            return
        }
        if Date().timeIntervalSince1970 - lastNotificationTimestamp >= 3600 && preferences.getSessionAuthHash() != nil {
            preferences.saveLastNotificationTimestamp(timeStamp: Date().timeIntervalSince1970)
            Task {
                await notificationRepo.loadNotifications()
            }
        }
        credentialsRepo.updateServerConfig()
        handleShortcutLaunch()
    }

    private func testConnectivity() -> Task<Void, Error> {
        return Task { @MainActor in
            do {
                try await ipRepository.getIp().retry(3).value
                testTask = nil
                self.logger.logI("LivecycleManager", "Internet connectivity validated for \(connectivity.getNetwork())!")
            } catch {
                testTask = nil
                self.logger.logE("LivecycleManager", "Connected to VPN but no internet. \(error)")
                try await self.validateLocation()
            }
        }
    }

    private func validateLocation() async throws {
        let id = locationsManager.getLastSelectedLocation()
        do {
            let updatedId = try await configManager.validateLocation(lastLocation: id)
            if let updatedId = updatedId, id != updatedId {
                logger.logI("LivecycleManager", "Location is not valid, updated to \(updatedId)")
                try await connectToVPN(updatedLocationId: updatedId)
            } else {
                logger.logI("LivecycleManager", "Location is valid connecting to same network.")
                try await connectToVPN(updatedLocationId: id)
            }
        } catch {
            logger.logE("LivecycleManager", "Error: \(error)")
            try await disconenctFromVPN()
        }
    }

    private func disconenctFromVPN() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.disconnectTask = self.configManager.disconnectAsync().sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished:
                        self.logger.logI("LivecycleManager", "Successfully disconnected from VPN.")
                        continuation.resume()
                    case let .failure(error):
                        self.logger.logE("LivecycleManager", "Error disconnecting from VPN \(error)")
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { _ in }
            )
        }
    }

    private func connectToVPN(updatedLocationId: String) async throws {
        let settings = vpnManager.makeUserSettings()
        var proto: ProtocolPort
        if let info = vpnManager.vpnInfo.value {
            proto = ProtocolPort(info.selectedProtocol, info.selectedPort)
        } else {
            proto = ProtocolPort(TextsAsset.wireGuard, "443")
        }
        try await withCheckedThrowingContinuation { continuation in
            self.connectTask = configManager.connectAsync(
                locationID: updatedLocationId,
                proto: proto.protocolName,
                port: proto.portName,
                vpnSettings: settings
            ).sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished:
                        self.logger.logI("LivecycleManager", "Successfully connected to VPN.")
                        continuation.resume()
                    case let .failure(error):
                        self.logger.logE("LivecycleManager", "Error connecting to VPN \(error)")
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { _ in self.logger.logI("LivecycleManager", "Updated from VPN connection.") }
            )
        }
    }

    private func handleShortcutLaunch() {
#if os(iOS)
        let shortcut = (UIApplication.shared.delegate as? AppDelegate)?.shortcutType ?? .none
        (UIApplication.shared.delegate as? AppDelegate)?.shortcutType = ShortcutType.none
        if shortcut == .networkSecurity {
            showNetworkSecurityTrigger.send(())
        } else if shortcut == .notifications {
            showNotificationsTrigger.send(())
        }
#endif
    }
}

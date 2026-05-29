//
//  LifecycleManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 08/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import UIKit
import NetworkExtension

protocol LifecycleManagerType {
    var showNetworkSecurityTrigger: PassthroughSubject<Void, Never> { get }
    var showNotificationsTrigger: PassthroughSubject<Void, Never> { get }
    var becameActiveTrigger: PassthroughSubject<Void, Never> { get }

    func onAppStart()
    func appEnteredForeground()
}

class LifecycleManager: LifecycleManagerType {
    private let logger: FileLogger
    private var sessionManager: SessionManager
    private let preferences: Preferences
    private let vpnManager: VPNManager
    private let vpnStateRepository: VPNStateRepository
    private let connectivity: ConnectivityManager
    private let credentialsRepo: CredentialsRepository
    private let notificationRepo: NotificationRepository
    private let ipRepository: IPRepository
    private let configManager: ConfigurationsManager
    private let connectivityManager: ProtocolManagerType
    private let locationsManager: LocationsManager
    private let antiCensorshipRepository: AntiCensorshipRepository
    private let wifiManager: WifiManager
    private let locationListRepository: LocationListRepository
    private let windowProvider: WindowProvider
    private let checkUpdateRepository: CheckUpdateRepository
    private let userSessionRepository: UserSessionRepository

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
         vpnStateRepository: VPNStateRepository,
         connectivity: ConnectivityManager,
         credentialsRepo: CredentialsRepository,
         notificationRepo: NotificationRepository,
         ipRepository: IPRepository,
         configManager: ConfigurationsManager,
         connectivityManager: ProtocolManagerType,
         locationsManager: LocationsManager,
         antiCensorshipRepository: AntiCensorshipRepository,
         wifiManager: WifiManager,
         locationListRepository: LocationListRepository,
         windowProvider: WindowProvider,
         checkUpdateRepository: CheckUpdateRepository,
         userSessionRepository: UserSessionRepository) {
        self.logger = logger
        self.sessionManager = sessionManager
        self.preferences = preferences
        self.vpnManager = vpnManager
        self.vpnStateRepository = vpnStateRepository
        self.connectivity = connectivity
        self.credentialsRepo = credentialsRepo
        self.notificationRepo = notificationRepo
        self.ipRepository = ipRepository
        self.configManager = configManager
        self.connectivityManager = connectivityManager
        self.locationsManager = locationsManager
        self.antiCensorshipRepository = antiCensorshipRepository
        self.wifiManager = wifiManager
        self.locationListRepository = locationListRepository
        self.windowProvider = windowProvider
        self.checkUpdateRepository = checkUpdateRepository
        self.userSessionRepository = userSessionRepository

        sessionManager.checkForDiscconectReasonTrigger
            .sink { [weak self] _ in
                Task {
                    await self?.disconnectToUpdateSession()
                }
            }
            .store(in: &cancellables)
    }

    /// Fresh app launch.
    func onAppStart() {
        Task {
            await recoverFromAppUpdateIfNeeded()
            await disconnectToUpdateSession()
            try? await connectivity.awaitNetwork(maxTime: 1.0)
            if userSessionRepository.sessionAuth != nil && connectivity.internetConnectionAvailable() {
                antiCensorshipRepository.refreshParams()
                if shouldCheckForUpdate() {
                    preferences.saveLastUpdateCheckTimestamp(timeStamp: Date().timeIntervalSince1970)
                    checkUpdateRepository.checkForUpdate()
                }
                await notificationRepo.loadNotifications()
            }
            try? await locationListRepository.updateLocations()
            try? await locationListRepository.updatedServerList()
        }
    }

    private func shouldCheckForUpdate() -> Bool {
        guard let lastCheck = preferences.getLastUpdateCheckTimestamp() else { return true }
        let oneDay: Double = 24 * 3600
        return Date().timeIntervalSince1970 - lastCheck >= oneDay
    }

    private func recoverFromAppUpdateIfNeeded() async {
        guard preferences.getTunnelStoppedForAppUpdate() else { return }

        logger.logI("LifecycleManager", "Recovering VPN profiles after app update.")
        await configManager.reloadManagers()
        await vpnManager.resetProfiles()
        preferences.saveTunnelStoppedForAppUpdate(status: false)
    }

    private func checkForKillSwitch() {
        vpnManager.configureForConnectionState()
        let info = vpnStateRepository.vpnInfo.value
        if connectivity.internetConnectionAvailable() {
            if info?.killSwitch == true && vpnStateRepository.isDisconnected() && !wifiManager.isConnectedWifiTrusted() {
                logger.logI("LifecycleManager", "VPN disocnnected, Turning off kill switch.")
                vpnManager.simpleDisableConnection()
            } else if vpnStateRepository.isConnected() && testTask == nil {
                logger.logI("LifecycleManager", "VPN conencted. testing conenctivity.")
                testTask = testConnectivity()
            }
        }
    }

    private func disconnectToUpdateSession() async {
        let error = await configManager.getGeneralConnectError()
        if preferences.getDisconnectReason() != .unknown || error == .authFailure {
            logger.logI("LifecycleManager", "Disconencting due to disconnect reason. \(preferences.getDisconnectReason())")
            await configManager.reloadManagers()
            await vpnManager.resetProfiles()
            preferences.saveDisconnectReason(reason: DisconnectReason.unknown)
            try? await Task.sleep(nanoseconds: 500_000_000)
            // Force update session after VPN recovery - cancels any pending updates
            do {
                try await sessionManager.updateSession(force: true)
                logger.logI("LifecycleManager", "Force session update completed after VPN recovery.")
            } catch {
                logger.logE("LifecycleManager", "Force session update failed: \(error)")
            }
        } else {
            sessionManager.keepSessionUpdated()
        }
    }

    /// App foreground.
    func appEnteredForeground() {
        logger.logI("LifecycleManager", "App internet moved to foreground.")
        checkForKillSwitch()
        Task {
            await disconnectToUpdateSession()
            becameActiveTrigger.send(())
            if connectivity.internetConnectionAvailable() {
                logger.logI("LifecycleManager", "Internet availble updating session. \(connectivity.getNetwork())")
                antiCensorshipRepository.tryRefresh()
                guard let lastNotificationTimestamp = preferences.getLastNotificationTimestamp() else {
                    preferences.saveLastNotificationTimestamp(timeStamp: Date().timeIntervalSince1970)
                    return
                }
                if Date().timeIntervalSince1970 - lastNotificationTimestamp >= 3600 && userSessionRepository.sessionAuth != nil {
                    preferences.saveLastNotificationTimestamp(timeStamp: Date().timeIntervalSince1970)
                    Task {
                        await notificationRepo.loadNotifications()
                    }
                }
                credentialsRepo.updateServerConfig()
            }
            await MainActor.run {
                handleShortcutLaunch()
            }
        }
    }

    private func testConnectivity() -> Task<Void, Error> {
        return Task { @MainActor in
            do {
                // Retry up to 3 times
                var lastError: Error?
                for attempt in 1...3 {
                    do {
                        try await ipRepository.getIp(usePingTest: true)
                        testTask = nil
                        self.logger.logI("LifecycleManager", "Internet connectivity validated for \(connectivity.getNetwork())!")
                        return
                    } catch {
                        lastError = error
                        if attempt < 3 {
                            self.logger.logI("LifecycleManager", "IP fetch attempt \(attempt) failed, retrying...")
                            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay between retries
                        }
                    }
                }
                throw lastError ?? Errors.notDefined
            } catch {
                testTask = nil
                self.logger.logE("LifecycleManager", "Connected to VPN but no internet. \(error)")
                try await self.validateLocation()
            }
        }
    }

    private func validateLocation() async throws {
        let id = locationsManager.getLastConnectionTarget()
        do {
            let updatedId = try await configManager.validateLocation(lastLocation: id)
            if let updatedId = updatedId, id != updatedId {
                logger.logI("LifecycleManager", "Location is not valid, updated to \(updatedId)")
                try await connectToVPN(updatedLocationId: updatedId)
            } else {
                logger.logI("LifecycleManager", "Location is valid connecting to same network.")
                try await connectToVPN(updatedLocationId: id)
            }
        } catch {
            logger.logE("LifecycleManager", "Error: \(error)")
            try await disconenctFromVPN()
        }
    }

    private func disconenctFromVPN() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.disconnectTask = self.configManager.disconnectAsync().sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished:
                        self.logger.logI("LifecycleManager", "Successfully disconnected from VPN.")
                        continuation.resume()
                    case let .failure(error):
                        self.logger.logE("LifecycleManager", "Error disconnecting from VPN \(error)")
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
        if let info = vpnStateRepository.vpnInfo.value {
            proto = ProtocolPort(info.selectedProtocol, info.selectedPort)
        } else {
            proto = ProtocolPort(VPNProtocolType.wireGuard.identifier, "443")
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
                        self.logger.logI("LifecycleManager", "Successfully connected to VPN.")
                        continuation.resume()
                    case let .failure(error):
                        self.logger.logE("LifecycleManager", "Error connecting to VPN \(error)")
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { _ in self.logger.logI("LifecycleManager", "Updated from VPN connection.") }
            )
        }
    }

    private func handleShortcutLaunch() {
#if os(iOS)
        let shortcut = windowProvider.shortcutType
        windowProvider.shortcutType = .none
        if shortcut == .networkSecurity {
            showNetworkSecurityTrigger.send(())
        } else if shortcut == .notifications {
            showNotificationsTrigger.send(())
        }

        if let url = windowProvider.pendingURL {
            windowProvider.pendingURL = nil
            handlePendingURL(url)
        }

        if let activityType = windowProvider.pendingActivityType {
            windowProvider.pendingActivityType = nil
            handlePendingActivity(activityType)
        }
#endif
    }

    private func handlePendingURL(_ url: URL) {
#if os(iOS)
        if url.absoluteString.contains("disconnect") {
            NotificationCenter.default.post(Notification(name: Notifications.disconnectVPN))
        } else {
            NotificationCenter.default.post(Notification(name: Notifications.connectToVPN))
        }
#endif
    }

    private func handlePendingActivity(_ activityType: String) {
#if os(iOS)
        if activityType == SiriIdentifiers.connect {
            NotificationCenter.default.post(Notification(name: Notifications.connectToVPN))
        } else if activityType == SiriIdentifiers.disconnect {
            NotificationCenter.default.post(Notification(name: Notifications.disconnectVPN))
        }
#endif
    }
}

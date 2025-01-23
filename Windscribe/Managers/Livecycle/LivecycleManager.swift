//
//  LivecycleManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 08/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import RxSwift
import UIKit
import NetworkExtension

protocol LivecycleManagerType {
    var showNetworkSecurityTrigger: PublishSubject<Void> { get }
    var showNotificationsTrigger: PublishSubject<Void> { get }
    var becameActiveTrigger: PublishSubject<Void> { get }

    func onAppStart()
    func appEnteredForeground()
}

class LivecycleManager: LivecycleManagerType {
    let logger: FileLogger
    let sessionManager: SessionManagerV2
    let preferences: Preferences
    let vpnManager: VPNManager
    let connectivity: Connectivity
    let credentialsRepo: CredentialsRepository
    let notificationRepo: NotificationRepository
    let ipRepository: IPRepository
    let configManager: ConfigurationsManager
    let connectivityManager: ProtocolManagerType
    let locationsManager: LocationsManagerType

    let showNetworkSecurityTrigger = PublishSubject<Void>()
    let showNotificationsTrigger = PublishSubject<Void>()
    let becameActiveTrigger = PublishSubject<Void>()
    let dispose = DisposeBag()
    var disconnectTask: AnyCancellable?
    var connectTask: AnyCancellable?
    var testTask: Task<Void, Error>?

    init(logger: FileLogger,
         sessionManager: SessionManagerV2,
         preferences: Preferences,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         credentialsRepo: CredentialsRepository,
         notificationRepo: NotificationRepository,
         ipRepository: IPRepository,
         configManager: ConfigurationsManager,
         connectivityManager: ProtocolManagerType,
         locationsManager: LocationsManagerType)
    {
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
        notificationRepo.loadNotifications()
    }

    private func checkForKillSwitch() {
        vpnManager.configureForConnectionState()
        let info = try? vpnManager.vpnInfo.value()
        if info?.killSwitch == true && vpnManager.isDisconnected() {
            vpnManager.simpleDisableConnection()
        } else if vpnManager.isConnected() && testTask == nil {
                logger.logD("LivecycleManager", "VPN conencted. testing conenctivity.")
                testTask = testConnectivity()
            }
    }

    /// App foreground.
    func appEnteredForeground() {
      //  checkForKillSwitch()
        logger.logD("LivecycleManager", "App internet moved to foreground.")
        becameActiveTrigger.onNext(())
        sessionManager.keepSessionUpdated()
        guard let lastNotificationTimestamp = preferences.getLastNotificationTimestamp() else {
            preferences.saveLastNotificationTimestamp(timeStamp: Date().timeIntervalSince1970)
            return
        }
        if Date().timeIntervalSince1970 - lastNotificationTimestamp >= 3600 {
            preferences.saveLastNotificationTimestamp(timeStamp: Date().timeIntervalSince1970)
            notificationRepo.loadNotifications()
        }
        credentialsRepo.updateServerConfig()
        handleShortcutLaunch()
    }

    private func testConnectivity() -> Task<Void, Error> {
        return Task { @MainActor in
            do {
                let network = connectivity.getNetwork()
                self.logger.logD("LivecycleManager", "Network: \(network)")
                let userIp = try await ipRepository.getIp().retry(3).value
                self.logger.logD("LivecycleManager", "Internet connectivity validated with user ip: \(userIp.userIp) Windscribe IP: \(userIp.isOurIp)")
                testTask = nil
            } catch {
                testTask = nil
                self.logger.logD("LivecycleManager", "Connected to VPN but no internet. \(error)")
                try await self.validateLocation()
            }
        }
    }

    private func validateLocation() async throws {
        let id = locationsManager.getLastSelectedLocation()
        do {
            let updatedId = try await configManager.validateLocation(lastLocation: id)
            if let updatedId = updatedId, id != updatedId {
                logger.logD("LivecycleManager", "Location is not valid, updated to \(updatedId)")
                try await connectToVPN(updatedLocationId: updatedId)
            } else {
                logger.logD("LivecycleManager", "Location is valid connecting to same network.")
                try await connectToVPN(updatedLocationId: id)
            }
        } catch {
            logger.logD("LivecycleManager", "Error: \(error)")
            try await disconenctFromVPN()
        }
    }

    private func disconenctFromVPN() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.disconnectTask = self.configManager.disconnectAsync().sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished:
                        self.logger.logD("LivecycleManager", "Successfully disconnected from VPN.")
                        continuation.resume()
                    case let .failure(error):
                        self.logger.logD("LivecycleManager", "Error disconnecting from VPN \(error)")
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { _ in }
            )
        }
    }

    private func connectToVPN(updatedLocationId: String) async throws {
        let settings = vpnManager.makeUserSettings()
        let proto = ProtocolPort(TextsAsset.wireGuard, "443")//TODO: vpnManager  - await vpnManager.getProtocolPort()

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
                        self.logger.logD("LivecycleManager", "Successfully connected to VPN.")
                        continuation.resume()
                    case let .failure(error):
                        self.logger.logD("LivecycleManager", "Error connecting to VPN \(error)")
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { _ in self.logger.logD("LivecycleManager", "Updated from VPN connection.") }
            )
        }
    }

    private func handleShortcutLaunch() {
#if os(iOS)
        let shortcut = (UIApplication.shared.delegate as? AppDelegate)?.shortcutType ?? .none
        (UIApplication.shared.delegate as? AppDelegate)?.shortcutType = ShortcutType.none
        if shortcut == .networkSecurity {
            showNetworkSecurityTrigger.onNext(())
        } else if shortcut == .notifications {
            showNotificationsTrigger.onNext(())
        }
#endif
    }
}

//
//  SceneActionHandler.swift
//  Windscribe
//
//  Created by Anthony on 2026-03-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import UIKit

protocol SceneActionHandler {
    func handleURL(_ url: URL) -> Bool
    func handleUserActivity(_ userActivity: NSUserActivity) -> Bool
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem)
}

class SceneActionHandlerImpl: SceneActionHandler {
    private let userSessionRepository: UserSessionRepository
    private let logger: FileLogger
    private let customConfigRepository: CustomConfigRepository
    private let alertManager: AlertManager
    private let windowProvider: WindowProvider

    init(userSessionRepository: UserSessionRepository,
         logger: FileLogger,
         customConfigRepository: CustomConfigRepository,
         alertManager: AlertManager,
         windowProvider: WindowProvider) {
        self.userSessionRepository = userSessionRepository
        self.logger = logger
        self.customConfigRepository = customConfigRepository
        self.alertManager = alertManager
        self.windowProvider = windowProvider
    }

    func handleURL(_ url: URL) -> Bool {
        guard userSessionRepository.sessionAuth != nil else { return true }

        if url.isFileURL && url.pathExtension == "ovpn" {
            logger.logI("SceneActionHandler", "Importing OpenVPN .ovpn file")
            Task {
                do {
                    try await customConfigRepository.saveOpenVPNConfig(url: url)
                    await showCustomConfigTab()
                } catch {
                    await showCustomConfigError(with: error)
                }
            }
        } else if url.isFileURL && url.pathExtension == "conf" {
            logger.logI("SceneActionHandler", "Importing WireGuard .conf file")
            Task {
                do {
                    try await customConfigRepository.saveWgConfig(url: url)
                    await showCustomConfigTab()
                } catch {
                    await showCustomConfigError(with: error)
                }
            }
        } else {
            if url.absoluteString.contains("disconnect") {
                NotificationCenter.default.post(Notification(name: Notifications.disconnectVPN))
            } else {
                NotificationCenter.default.post(Notification(name: Notifications.connectToVPN))
            }
        }
        return true
    }

    func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard userSessionRepository.sessionAuth != nil else { return true }

        if userActivity.activityType == SiriIdentifiers.connect {
            NotificationCenter.default.post(Notification(name: Notifications.connectToVPN))
        } else if userActivity.activityType == SiriIdentifiers.disconnect {
            NotificationCenter.default.post(Notification(name: Notifications.disconnectVPN))
        }
        return true
    }

    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        guard userSessionRepository.sessionAuth != nil else { return }

        if shortcutItem.type.contains("Notifications") {
            windowProvider.shortcutType = .notifications
        } else if shortcutItem.type.contains("NetworkSecurity") {
            windowProvider.shortcutType = .networkSecurity
        }
    }

    @MainActor
    private func showCustomConfigTab() async {
        NotificationCenter.default.post(Notification(name: Notifications.showCustomConfigTab))
    }

    @MainActor
    private func showCustomConfigError(with error: Error) async {
        if let error = error as? RepositoryError {
            await MainActor.run {
                alertManager.showSimpleAlert(title: TextsAsset.error, message: error.description, buttonText: TextsAsset.okay)
            }
        }
    }
}

//
//  CheckUpdateRepositoryImpl.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-04-13.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UIKit

class CheckUpdateRepositoryImpl: CheckUpdateRepository {
    private let apiManager: APIManager
    private let preferences: Preferences
    private let logger: FileLogger

    let updateAvailable = CurrentValueSubject<CheckUpdateModel?, Never>(nil)

    init(apiManager: APIManager, preferences: Preferences, logger: FileLogger) {
        self.apiManager = apiManager
        self.preferences = preferences
        self.logger = logger
    }

    func checkForUpdate() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let model = try await self.apiManager.checkUpdate(
                    appVersion: Bundle.main.releaseVersionNumber ?? "",
                    appBuild: Bundle.main.buildVersionNumber ?? "",
                    osVersion: UIDevice.current.systemVersion
                )
                self.logger.logD("CheckUpdateRepository", "Update available: \(model.updateAvailable), version: \(model.latestVersion ?? "unknown"), force: \(model.force)")
                // Force-upgrade bypasses the 24h gate so a force-quit within the window still re-prompts on cold launch.
                if model.force {
                    self.preferences.saveLastUpdateCheckTimestamp(timeStamp: nil)
                }
                self.updateAvailable.send(model)
            } catch {
                self.logger.logE("CheckUpdateRepository", "Check update failed: \(error)")
            }
        }
    }
}

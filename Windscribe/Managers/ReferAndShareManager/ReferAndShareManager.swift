//
//  ReferAndShareManager.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-03-27.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol ReferAndShareManager {
    func checkAndShowDialogFirstTime() async -> Bool
    func setShowedShareDialog(showed: Bool)
}

class ReferAndShareManagerImpl: ReferAndShareManager {
    private let sessionRepository: SessionRepository
    private let preference: Preferences
    private let vpnManager: VPNManager
	private let logger: FileLogger

    init(preferences: Preferences,
         sessionRepository: SessionRepository,
         vpnManager: VPNManager,
         logger: FileLogger) {
        preference = preferences
        self.sessionRepository = sessionRepository
        self.vpnManager = vpnManager
        self.logger = logger
    }

    func checkAndShowDialogFirstTime() async -> Bool {
        guard !preference.getShowedShareDialog() else {
            return false
        }

        guard await vpnManager.isActive() else {
            return false
        }

        return await MainActor.run {
            guard let session = sessionRepository.session else {
                return false
            }
            let regDate = session.regDate

            let registerDate = Date(timeIntervalSince1970: TimeInterval(regDate))
            let daysRegisteredSince = Calendar.current.numberOfDaysBetween(registerDate, and: Date())

            if !session.isUserPro && !session.isUserGhost && daysRegisteredSince > 30 {
                self.setShowedShareDialog()

                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                }

                return true
            }

            return false
        }
    }

    func setShowedShareDialog(showed: Bool = true) {
        preference.saveShowedShareDialog(showed: showed)
    }
}

//
//  ReferAndShareManager.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-03-27.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject
class ReferAndShareManager: ReferAndShareManagerV2 {
    private let preference: Preferences
    private let disposeBag = DisposeBag()

    private let sessionManager: SessionManagerV2, logger: FileLogger
    static let shared = ReferAndShareManager(preferences: SharedSecretDefaults.shared, sessionManager: Assembler.resolve(SessionManagerV2.self), logger: Assembler.resolve(FileLogger.self))

    init(preferences: Preferences, sessionManager: SessionManagerV2, logger: FileLogger) {
        self.preference = preferences
        self.sessionManager = sessionManager
        self.logger = logger
    }

    func checkAndShowDialogFirstTime(completion: @escaping () -> Void) {
        guard !didShowedDialog() else {
            return
        }
        guard VPNManager.shared.isActive else {
            return
        }

        guard let connectionCount = preference.getConnectionCount() else {
            return
        }

        if !(sessionManager.session?.isUserPro ?? false)
            && !(sessionManager.session?.isUserGhost ?? false)
            && connectionCount > 15 {
            logger.logD(self, "Share with friends dialog shown for free user as connectionCount is more than 15")
            setShowedShareDialog()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                completion()
            }
        }
    }

    func didShowedDialog() -> Bool {
        return preference.getShowedShareDialog()
    }

    func setShowedShareDialog(showed: Bool = true) {
        preference.saveShowedShareDialog(showed: showed)
    }
}

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
    private let disposeBag = DisposeBag()

    private let sessionManager: SessionManagerV2
    private let preference: Preferences
    private let vpnManager: VPNManager

    static let shared = ReferAndShareManager(preferences: SharedSecretDefaults.shared, sessionManager: Assembler.resolve(SessionManagerV2.self), vpnManager: Assembler.resolve(VPNManager.self))

    init(preferences: Preferences, sessionManager: SessionManagerV2, vpnManager: VPNManager) {
        preference = preferences
        self.sessionManager = sessionManager
        self.vpnManager = vpnManager
    }

    func checkAndShowDialogFirstTime(completion: @escaping () -> Void) {
        guard !didShowedDialog() else {
            return
        }
        Task {
            guard await vpnManager.isActive() else { return }
            safeSession { session in
                guard let regDate = session?.regDate else { return }
                let registerDate = Date(timeIntervalSince1970: TimeInterval(regDate))
                let daysRegisteredSince = Calendar.current.numberOfDaysBetween(registerDate, and: Date())
                if !(session?.isUserPro ?? false)
                    && !(session?.isUserGhost ?? false)
                    && daysRegisteredSince > 30
                {
                    self.setShowedShareDialog()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        completion()
                    }
                }
            }
        }
    }

    func safeSession(completion: @escaping (Session?) -> Void) {
        DispatchQueue.main.async {
            completion(self.sessionManager.session)
        }
    }

    func didShowedDialog() -> Bool {
        return preference.getShowedShareDialog()
    }

    func setShowedShareDialog(showed: Bool = true) {
        preference.saveShowedShareDialog(showed: showed)
    }
}

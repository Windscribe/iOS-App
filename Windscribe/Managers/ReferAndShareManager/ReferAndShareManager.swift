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

    private let sessionManager: SessionManagerV2
    static let shared = ReferAndShareManager(preferences: SharedSecretDefaults.shared, sessionManager: Assembler.resolve(SessionManagerV2.self))

    init(preferences: Preferences, sessionManager: SessionManagerV2) {
        self.preference = preferences
        self.sessionManager = sessionManager
    }

    func checkAndShowDialogFirstTime(completion: @escaping () -> Void) {
        guard !didShowedDialog() else {
            return
        }
        guard VPNManager.shared.isActive else {
            return
        }
        guard let regDate = sessionManager.session?.regDate else {
            return
        }
        let registerDate = Date(timeIntervalSince1970: TimeInterval(regDate))
        let daysRegisteredSince = Calendar.current.numberOfDaysBetween(registerDate, and: Date())
        if !(sessionManager.session?.isUserPro ?? false)
            && !(sessionManager.session?.isUserGhost ?? false)
            && daysRegisteredSince > 30 {
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

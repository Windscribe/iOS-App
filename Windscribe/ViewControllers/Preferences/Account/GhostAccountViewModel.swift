//
//  GhostAccountViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol GhostAccountViewModelType {
    var isDarkMode: BehaviorSubject<Bool> { get }
    func isUserPro() -> Bool?
}

class GhostAccountViewModel: GhostAccountViewModelType {
    let sessionManager: SessionManagerV2
    let isDarkMode: BehaviorSubject<Bool>

    init(sessionManager: SessionManagerV2, themeManager: ThemeManager) {
        self.sessionManager = sessionManager
        isDarkMode = themeManager.darkTheme
    }

    func isUserPro() -> Bool? {
       return sessionManager.session?.isUserPro
    }
}

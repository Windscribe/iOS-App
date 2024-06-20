//
//  GhostAccountViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol GhostAccountViewModelType {
    func isUserPro() -> Bool?
}

class GhostAccountViewModel: GhostAccountViewModelType {

    var sessionManager: SessionManagerV2

    init(sessionManager: SessionManagerV2) {
        self.sessionManager = sessionManager
    }

    func isUserPro() -> Bool? {
       return sessionManager.session?.isUserPro
    }
}

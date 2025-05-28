//
//  GhostAccountViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-09.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import Foundation

protocol GhostAccountViewModel: ObservableObject {
    var isUserPro: Bool { get }
}

class GhostAccountViewModelImpl: GhostAccountViewModel {

    private let sessionManager: SessionManaging

    var isUserPro: Bool {
        sessionManager.session?.isUserPro ?? false
    }

    init(sessionManager: SessionManaging) {
        self.sessionManager = sessionManager
    }
}

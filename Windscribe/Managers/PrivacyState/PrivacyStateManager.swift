//
//  PrivacyStateManager.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol PrivacyStateManaging {
    var privacyAcceptedSubject: PassthroughSubject<Void, Never> { get }

    func notifyPrivacyAccepted()
}

class PrivacyStateManager: PrivacyStateManaging {
    let privacyAcceptedSubject = PassthroughSubject<Void, Never>()

    private let logger: FileLogger

    init(logger: FileLogger) {
        self.logger = logger
    }

    func notifyPrivacyAccepted() {
        logger.logI("PrivacyStateManager", "Privacy acceptance notification sent")
        privacyAcceptedSubject.send(())
    }
}

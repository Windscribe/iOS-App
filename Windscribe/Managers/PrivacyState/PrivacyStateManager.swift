//
//  PrivacyStateManager.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol PrivacyStateManaging {
    var privacyAcceptedSubject: PublishSubject<Void> { get }

    func notifyPrivacyAccepted()
}

class PrivacyStateManager: PrivacyStateManaging {
    let privacyAcceptedSubject = PublishSubject<Void>()

    private let logger: FileLogger

    init(logger: FileLogger) {
        self.logger = logger
    }

    func notifyPrivacyAccepted() {
        logger.logI("PrivacyStateManager", "Privacy acceptance notification sent")
        privacyAcceptedSubject.onNext(())
    }
}

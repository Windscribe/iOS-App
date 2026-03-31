//
//  MockAntiCensorshipRepository.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-03-31.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine

@testable import Windscribe

class MockAntiCensorshipRepository: AntiCensorshipRepository {

    var useProtocolTweaksSubject: CurrentValueSubject<Bool, Never> = .init(false)

    var selecteRoutingTypeSubject: CurrentValueSubject<Windscribe.ServerRoutingType, Never> = .init(Windscribe.ServerRoutingType.auto)

    var selectedWgParamSubject: CurrentValueSubject<Windscribe.UnblockWgParams?, Never> = .init(nil)

    var unlockParams: [Windscribe.UnblockWgParams] = []

    func setServerRoutingType(_ value: Windscribe.ServerRoutingType) {

    }

    func setUseProtocolTweaks(_ value: Bool) {

    }

    func setWgParameter(withId id: String) {

    }

    func setSessionWgParameter(withId id: String) {

    }

    func needsRefresh() -> Bool {
        false
    }

    func tryRefresh() {

    }

    func refreshParams() {

    }


}

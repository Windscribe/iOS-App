//
//  IKEv2IntentVPNManager.swift
//  SiriIntents
//
//  Created by Andre Fonseca on 30/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension

class IKEv2IntentVPNManager: IntentVPNManagerType {
    let neVPNManager = NEVPNManager.shared()
    var setupCompleted = false
    var logger: FileLogger
    var kcDb: KeyChainDatabase

    init(logger: FileLogger, kcDb: KeyChainDatabase) {
        self.logger = logger
        self.kcDb = kcDb
    }

    func getProviderManager() -> NEVPNManager? {
        return neVPNManager
    }

    func setup(completion: @escaping () -> Void) {
        guard !setupCompleted else {
            completion()
            return
        }
        neVPNManager.loadFromPreferences { _ in
            self.setupCompleted = true
            completion()
        }
    }

    func isConfigured() -> Bool {
        return neVPNManager.protocolConfiguration?.username != nil
    }
}

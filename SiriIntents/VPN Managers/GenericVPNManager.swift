//
//  GenericVPNManager.swift
//  SiriIntents
//
//  Created by Andre Fonseca on 30/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension

class GenericVPNManager: IntentVPNManagerType {
    let userName: VPNManagerUserName
    var providerManager: NETunnelProviderManager!
    var setupCompleted = false
    var logger: FileLogger
    var kcDb: KeyChainDatabase

    init(userName: VPNManagerUserName, logger: FileLogger, kcDb: KeyChainDatabase) {
        self.userName = userName
        self.logger = logger
        self.kcDb = kcDb
    }

    func getProviderManager() -> NEVPNManager? {
        return providerManager
    }

    func isConfigured() -> Bool {
        return providerManager?.protocolConfiguration?.username == userName.rawValue
    }

    func setup(completion: @escaping () -> Void) {
        guard !setupCompleted else {
            completion()
            return
        }
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard let self = self else { return }
            self.setupCompleted = true
            if error == nil {
                self.providerManager = managers?.first {
                    $0.protocolConfiguration?.username == self.userName.rawValue
                } ?? NETunnelProviderManager()
                completion()
            } else {
                completion()
            }
        }
    }
}

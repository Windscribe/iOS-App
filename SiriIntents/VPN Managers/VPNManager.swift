//
//  VPNManager.swift
//  SiriIntents
//
//  Created by Andre Fonseca on 30/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

class VPNManager {
    var logger: FileLogger
    var kcDb: KeyChainDatabase
    lazy var openVPNManager: VPNManagerType = {
        GenericVPNManager(userName: .openVPN, logger: logger, kcDb: kcDb)
    }()
    lazy var wireguardVPNManager: VPNManagerType = {
        GenericVPNManager(userName: .wireGuard, logger: logger, kcDb: kcDb)
    }()
    lazy var ikev2VPNManager: VPNManagerType = {
        IKEv2VPNManager(logger: logger, kcDb: kcDb)
    }()

    init(logger: FileLogger, kcDb: KeyChainDatabase) {
        self.logger = logger
        self.kcDb = kcDb
    }

    var isActive: Bool {
        return openVPNManager.isConfigured() || wireguardVPNManager.isConfigured() || ikev2VPNManager.isConfigured()
    }

    func isConnected() -> Bool {
        return (ikev2VPNManager.isConnected() && ikev2VPNManager.isConfigured()) ||
        (openVPNManager.isConnected() && openVPNManager.isConfigured()) ||
        (wireguardVPNManager.isConnected() && wireguardVPNManager.isConfigured())
    }

    func setup(completion: @escaping() -> Void) {
        ikev2VPNManager.setup{
            self.openVPNManager.setup {
                self.wireguardVPNManager.setup {
                    completion()
                }
            }
        }
    }

    func connect(completion: @escaping(_ result: Bool) -> Void) {
        [(openVPNManager, [ikev2VPNManager, wireguardVPNManager]),
         (wireguardVPNManager, [ikev2VPNManager, openVPNManager]),
         (ikev2VPNManager, [openVPNManager, wireguardVPNManager])].forEach {
            if $0.isDisconnected() && $0.isConfigured() {
                $0.connect(otherProviders: $1) { completion($0) }
                return
            }
        }
    }

    func disconnect(completion: @escaping(_ result: Bool) -> Void) {
        [ikev2VPNManager, openVPNManager, wireguardVPNManager].forEach {
            if $0.isConnected() {
                $0.disconnect() { completion($0) }
                return
            }
        }
    }
}

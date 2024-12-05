//
//  ConfigurationsManager+Connections.swift
//  Windscribe
//
//  Created by Andre Fonseca on 29/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import NetworkExtension
import Swinject
import RxSwift

extension ConfigurationsManager {
    func removeProfile(with type: VPNManagerType, killSwitch: Bool) async {
        guard let manager = getManager(for: type) else { return }
        await removeProfile(killSwitch: killSwitch, manager: manager)
    }

    func removeProfile(killSwitch: Bool, manager: NEVPNManager) async {
        guard (try? await manager.loadFromPreferences()) != nil else { return }
        if manager.protocolConfiguration?.username != nil {
            await disconnect(killSwitch: killSwitch, manager: manager)
            await remove(manager: manager)
        }
    }

    func disconnect(restartOnDisconnect: Bool = false, force: Bool = false, killSwitch: Bool, manager: NEVPNManager, connectIntent: Bool = false) async {
        if manager.connection.status == .disconnected, !force { return }
        guard (try? await manager.loadFromPreferences()) != nil else { return }
        if manager.protocolConfiguration?.username != nil {
            manager.isOnDemandEnabled = connectIntent
            #if os(iOS)
                if #available(iOS 15.1, *) {
                    if restartOnDisconnect {
                        manager.protocolConfiguration?.includeAllNetworks = false
                    } else {
                        manager.protocolConfiguration?.includeAllNetworks = killSwitch
                    }
                }
            #endif
            try? await saveToPreferences(manager: manager)
            manager.connection.stopVPNTunnel()
        }
    }
}

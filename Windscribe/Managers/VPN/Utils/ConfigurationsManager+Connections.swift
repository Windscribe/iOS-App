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
    func removeProfile(with type: VPNManagerType, userSettings: VPNUserSettings) async {
        guard let manager = getManager(for: type) else { return }
        await removeProfile(userSettings: userSettings, manager: manager)
    }

    func removeProfile(userSettings: VPNUserSettings, manager: NEVPNManager) async {
        guard (try? await manager.loadFromPreferences()) != nil else { return }
        if manager.protocolConfiguration?.username != nil {
            await disconnect(userSettings: userSettings, manager: manager)
            await remove(manager: manager)
        }
    }

    func disconnect(restartOnDisconnect: Bool = false, force: Bool = false, userSettings: VPNUserSettings, manager: NEVPNManager, connectIntent: Bool = false) async {
        if manager.connection.status == .disconnected, !force { return }
        guard (try? await manager.loadFromPreferences()) != nil else { return }
        if manager.protocolConfiguration?.username != nil {
            manager.isOnDemandEnabled = connectIntent
            #if os(iOS)
                if #available(iOS 15.1, *) {
                    if restartOnDisconnect {
                        manager.protocolConfiguration?.includeAllNetworks = false
                    } else {
                        manager.protocolConfiguration?.includeAllNetworks = userSettings.killSwitch
                    }
                }
            #endif
            try? await saveToPreferences(manager: manager)
            manager.connection.stopVPNTunnel()
        }
    }
}

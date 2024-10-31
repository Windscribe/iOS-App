//
//  VPNManagerUtil+Connecions.swift
//  Windscribe
//
//  Created by Andre Fonseca on 29/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import NetworkExtension

extension VPNManagerUtils {
    func connect() {
        // UserSettings - allowLane, killSwitch, etc
        // Credentials
        // Protocol, Port
        // LocaionID
    }

    func getManager(for type: VPNManagerType) -> NEVPNManager? {
        switch type {
        case .iKEV2: iKEV2Manager()
        case .wg: wireguardManager()
        case .openVPN: openVPNdManager()
        }
    }

    func connect(with type: VPNManagerType, killSwitch: Bool) async {
        VPNManager.shared.activeVPNManager = type

        guard let manager = getManager(for: type) else { return }
        let otherManagers = Array(Set(managers).subtracting([manager]))

        for otherManager in otherManagers {
            if otherManager.connection.status == .connected {
                delegate?.setRestartOnDisconnect(with: true)
                await disconnect(killSwitch: killSwitch, manager: otherManager)
                break
            }
        }
        if manager.connection.status == .connected || manager.connection.status == .connecting {
            delegate?.setRestartOnDisconnect(with: true)
            await restartConnection(killSwitch: killSwitch, manager: manager)
        } else {
            for otherManager in otherManagers {
                await removeProfile(killSwitch: killSwitch, manager: otherManager)
            }
            manager.isOnDemandEnabled = DefaultValues.firewallMode
            manager.isEnabled = true
            await save(manager: manager)
            do {
                try manager.connection.startVPNTunnel(options: getTunnelParams(for: type))
                handleVPNManagerNoResponse(for: type, killSwitch: killSwitch)
                self.logger.logD(VPNManagerUtils.self, "WireGuard tunnel started.")

            } catch {
                self.logger.logE(VPNManagerUtils.self, "Error occured when establishing WireGuard connection: \(error.localizedDescription)")
            }
        }
    }

    func restartConnection(killSwitch: Bool, manager: NEVPNManager) async {
        logger.logD(VPNManagerUtils.self, "Restarting OpenVPN connection.")
        await disconnect(restartOnDisconnect: true, killSwitch: killSwitch, manager: manager)
    }

    func disconnect(with type: VPNManagerType, restartOnDisconnect: Bool = false, force: Bool = false, killSwitch: Bool) async {
        guard let manager = getManager(for: type) else { return }
        await disconnect(restartOnDisconnect: restartOnDisconnect, force: force, killSwitch: killSwitch, manager: manager)
    }

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

    func disconnect(restartOnDisconnect: Bool = false, force: Bool = false, killSwitch: Bool, manager: NEVPNManager) async {
        if manager.connection.status == .disconnected && !force { return }
        guard (try? await manager.loadFromPreferences()) != nil else { return }
        if manager.protocolConfiguration?.username != nil {
            manager.isOnDemandEnabled = VPNManager.shared.connectIntent
#if os(iOS)
            if #available(iOS 15.1, *) {
                if restartOnDisconnect {
                    manager.protocolConfiguration?.includeAllNetworks = false
                } else {
                    manager.protocolConfiguration?.includeAllNetworks = killSwitch
                }
            }
#endif
            await save(manager: manager)
            manager.connection.stopVPNTunnel()
        }
    }
    
    func invalidateTimer() {
        noResponseTimer?.invalidate()
    }

    private func getTunnelParams(for type: VPNManagerType) -> [String: NSObject]? {
        if type == .wg,
           let activationId = wgCredentials.address?.SHA1() as? NSObject {
            return ["activationAttemptId": activationId]
        } else {
            return nil
        }
    }

    /// Sometimes If another ikev2 profile is configured and kill switch is on VPNManager may not respond.
    private func handleVPNManagerNoResponse(for type: VPNManagerType, killSwitch: Bool) {
        if type == .iKEV2, killSwitch {
            noResponseTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { _ in
                VPNManager.shared.disconnectOrFail()
            }
        }
    }
}

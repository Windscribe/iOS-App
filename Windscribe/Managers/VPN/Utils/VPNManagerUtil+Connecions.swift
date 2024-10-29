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
    
    func getManager(for type: VPNManagerType, from managers: [NEVPNManager]) -> NEVPNManager? {
        switch type {
        case .iKEV2: iKEV2(from: managers)
        case .wg: wireguardManager(from: managers)
        case .openVPN: openVPNdManager(from: managers)
        }
    }
    
    func connect(with type: VPNManagerType) async {
        VPNManager.shared.activeVPNManager = type
        
        guard let managers = try? await getAllManagers(),
              let manager = getManager(for: type, from: managers) else { return }
        let otherManagers = Array(Set(managers).subtracting([manager]))
        
        
        for otherManager in otherManagers {
            if otherManager.connection.status == .connected {
                //                VPNManager.shared.restartOnDisconnect = true
                //                OpenVPNManager.shared.disconnect()
                break
            }
            
            if manager.connection.status == .connected || manager.connection.status == .connecting {
                //            VPNManager.shared.restartOnDisconnect = true
                //            WireGuardVPNManager.shared.restartConnection()
            } else {
                otherManagers.forEach { otherManager in
                    // Remove Profile
                }
                
                manager.isOnDemandEnabled = DefaultValues.firewallMode
                manager.isEnabled = true
                await save(manager: manager)
                do {
                    try manager.connection.startVPNTunnel(options: getTunnelParams(for: type))
                    handleVPNManagerNoResponse(for: type)
                    self.logger.logD(WireGuardVPNManager.self, "WireGuard tunnel started.")
                    
                } catch {
                    self.logger.logE(WireGuardVPNManager.self, "Error occured when establishing WireGuard connection: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getTunnelParams(for type: VPNManagerType) -> [String : NSObject]? {
        if type == .wg,
           let activationId = wgCredentials.address?.SHA1() as? NSObject {
            return ["activationAttemptId": activationId]
        } else {
            return nil
        }
    }
    
    /// Sometimes If another ikev2 profile is configured and kill switch is on VPNManager may not respond.
    private func handleVPNManagerNoResponse(for type: VPNManagerType) {
//        if type == .iKEV2, self.killSwitch {
//            noResponseTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { _ in
//                VPNManager.shared.disconnectOrFail()
//            }
//        }
    }
}

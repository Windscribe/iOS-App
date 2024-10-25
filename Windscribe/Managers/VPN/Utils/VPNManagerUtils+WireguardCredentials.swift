//
//  VPNManagerUtils+WireguardCredentials.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//


import NetworkExtension
import UIKit
import WireGuardKit

extension VPNManagerUtils {
    func getWireguardConfiguration(selectedNode: SelectedNode?) async throws -> TunnelConfiguration? {
        var configFilePath = "config.conf"
        if let customConfig = selectedNode?.customConfig,
           let customConfigId = customConfig.id {
            configFilePath = "\(customConfigId).conf"
        }
        guard let configData = fileDatabase.readFile(path: configFilePath),
              let stringData = String(data: configData, encoding: String.Encoding.utf8) else { return nil }
        var tunnelConfiguration: TunnelConfiguration?
        do {
            tunnelConfiguration =  try TunnelConfiguration(fromWgQuickConfig: stringData, called: configFilePath)
            return tunnelConfiguration
        } catch let error {
            logger.logE(WireGuardVPNManager.self, "WireGuard tunnel Error: \(error)")
            throw error
        }
    }
    
    func configureWireguard(with selectedNode: SelectedNode?,
                   for manager: NEVPNManager,
                   userSettings: VPNUserSettings)  async throws -> Bool {
        guard let providerManager = manager as? NETunnelProviderManager,
              let tunnelConfiguration = try await getWireguardConfiguration(selectedNode: selectedNode)
        else { return false }
        providerManager.setTunnelConfiguration(tunnelConfiguration, username: TextsAsset.wireGuard, description: Constants.appName)
#if os(iOS)
        // Changes made for Non Rfc-1918 . includeallnetworks​ =  True and excludeLocalNetworks​ = False
        if #available(iOS 15.1, *) {
            manager.protocolConfiguration?.includeAllNetworks = userSettings.isRFC ? userSettings.killSwitch : true
            manager.protocolConfiguration?.excludeLocalNetworks = userSettings.isRFC ? userSettings.allowLane : false
        }
        // iOS 16.0+ excludeLocalNetworks does'nt get enforced without killswitch.
        if #available(iOS 16.0, *) {
            manager.protocolConfiguration?.includeAllNetworks = userSettings.allowLane
        }
#endif
        providerManager.onDemandRules?.removeAll()
        providerManager.onDemandRules = userSettings.onDemandRules
        providerManager.isEnabled = true
        do {
            try await VPNManagerUtils.saveThrowing(manager: manager)
        } catch let error {
            guard let error = error as? Errors else { throw Errors.notDefined }
            logger.logE(self, "Error when saving vpn preferences \(error.description).")
            throw error
        }
        
        logger.logD( WireGuardVPNManager.self, "WireGuard VPN configuration successful.")
        return true
    }
}

//
//  ConfigurationsManager+Wireguard.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import NetworkExtension
import UIKit
import WireGuardKit

extension ConfigurationsManager {
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
            tunnelConfiguration = try TunnelConfiguration(fromWgQuickConfig: stringData, called: configFilePath)
            return tunnelConfiguration
        } catch {
            logger.logE(ConfigurationsManager.self, "WireGuard tunnel Error: \(error)")
            throw error
        }
    }

    func configureWireguard(with selectedNode: SelectedNode?,
                            userSettings: VPNUserSettings) async throws -> Bool {
        guard let selectedNode = selectedNode,
              let tunnelConfiguration = try await getWireguardConfiguration(selectedNode: selectedNode)
        else {
            return false
        }
        let providerManager = wireguardManager() as? NETunnelProviderManager ?? NETunnelProviderManager()
        providerManager.setTunnelConfiguration(tunnelConfiguration, username: TextsAsset.wireGuard, description: Constants.appName)
        #if os(iOS)
            // Changes made for Non Rfc-1918 . includeallnetworks​ =  True and excludeLocalNetworks​ = False
            if #available(iOS 15.1, *) {
                providerManager.protocolConfiguration?.includeAllNetworks = userSettings.isRFC ? userSettings.killSwitch : true
                providerManager.protocolConfiguration?.excludeLocalNetworks = userSettings.isRFC ? userSettings.allowLane : false
            }
            // iOS 16.0+ excludeLocalNetworks does'nt get enforced without killswitch.
            if #available(iOS 16.0, *) {
                providerManager.protocolConfiguration?.includeAllNetworks = userSettings.allowLane
            }
        #endif
        providerManager.onDemandRules?.removeAll()
        providerManager.onDemandRules = userSettings.onDemandRules
        providerManager.isEnabled = true
        providerManager.localizedDescription = Constants.appName

        do {
            try await saveThrowing(manager: providerManager)
        } catch {
            guard let error = error as? Errors else { throw Errors.notDefined }
            logger.logE(self, "Error when saving vpn preferences \(error.description).")
            throw error
        }

        logger.logD(ConfigurationsManager.self, "VPN configuration successful. Username: \(TextsAsset.wireGuard)")
        return true
    }

    // This could potentially be an enum
    func configureWireguardWithSavedConfig(selectedNode: SelectedNode?,
                                           userSettings: VPNUserSettings) async throws -> Bool {
        guard let ip3 = selectedNode?.ip3 else { return false }
        return try await configureWireguardWithConfig(selectedNode: selectedNode,
                                                      userSettings: userSettings,
                                                      logMessage: "Configuring VPN profile with saved configuration. \(String(describing: ip3))")
    }

    func configureWireguardWithCustomConfig(selectedNode: SelectedNode?,
                                            userSettings: VPNUserSettings) async throws -> Bool {
        guard let serverAddress = selectedNode?.serverAddress else { return false }
        return try await configureWireguardWithConfig(selectedNode: selectedNode,
                                                      userSettings: userSettings,
                                                      logMessage: "Configuring VPN profile with custom configuration. \(String(describing: serverAddress))")
    }

    private func configureWireguardWithConfig(selectedNode: SelectedNode?,
                                              userSettings: VPNUserSettings, logMessage: String) async throws -> Bool {
        logger.logD(ConfigurationsManager.self, logMessage)
        if wireguardManager()?.connection.status != .connecting {
            return try await configureWireguard(with: selectedNode, userSettings: userSettings)
        }
        return false
    }
}

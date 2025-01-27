//
//  NETunnelProviderManager+Ext.swift
//  WireGuardTunnel
//
//  Created by Ginder Singh on 2023-03-10.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import WireGuardKit

extension NETunnelProviderManager {
    private static var cachedConfigKey: UInt8 = 0

    var tunnelConfiguration: TunnelConfiguration? {
        if let cached = objc_getAssociatedObject(self, &NETunnelProviderManager.cachedConfigKey) as? TunnelConfiguration {
            return cached
        }
        let config = (protocolConfiguration as? NETunnelProviderProtocol)?.asTunnelConfiguration(called: localizedDescription)
        if config != nil {
            objc_setAssociatedObject(self, &NETunnelProviderManager.cachedConfigKey, config, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return config
    }

    func setTunnelConfiguration(_ tunnelConfiguration: TunnelConfiguration, username: String, description: String) {
        protocolConfiguration = NETunnelProviderProtocol(tunnelConfiguration: tunnelConfiguration, previouslyFrom: protocolConfiguration)
        protocolConfiguration?.username = username
        protocolConfiguration?.disconnectOnSleep = false
        localizedDescription = description
        objc_setAssociatedObject(self, &NETunnelProviderManager.cachedConfigKey, tunnelConfiguration, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

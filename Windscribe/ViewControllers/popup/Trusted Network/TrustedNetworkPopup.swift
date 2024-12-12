//
//  TrustedNetworkPopup.swift
//  Windscribe
//
//  Created by Bushra Sagir on 17/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol TrustedNetworkPopupType {
    func trustNetworkAction()
    func getConnectedWifiNetworkSSID() -> String
}

class TrustedNetworkPopup: TrustedNetworkPopupType {
    var securedNetwork: SecuredNetworkRepository
    var vpnManager: VPNManager
    var logger: FileLogger

    init(securedNetwork: SecuredNetworkRepository, vpnManager: VPNManager, logger: FileLogger) {
        self.securedNetwork = securedNetwork
        self.vpnManager = vpnManager
        self.logger = logger
    }

    func trustNetworkAction() {
        let currentNetwork = securedNetwork.getCurrentNetwork()
        logger.logD(self, "User tapped Protect Me button while in a trusted network.")
        vpnManager.untrustedOneTimeOnlySSID = currentNetwork?.SSID ?? ""
        _ = vpnManager.enableConnection()
    }

    func getConnectedWifiNetworkSSID() -> String {
        return securedNetwork.getCurrentNetwork()?.SSID ?? ""
    }
}

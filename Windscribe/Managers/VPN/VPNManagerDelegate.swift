//
//  VPNManagerDelegate.swift
//  Windscribe
//
//  Created by Thomas on 10/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation

protocol VPNManagerDelegate: AnyObject {
    func selectedNodeChanged()
    func setDisconnected()
    func setDisconnecting()
    func setConnectivityTest()
    func setConnected(ipAddress: String)
    func setAutomaticModeFailed()
    func setConnecting()
    func showAutomaticModeFailedToConnectPopup()
    func saveDataForWidget()
    func displaySetPrefferedProtocol()
    func disconnectVpn()
}

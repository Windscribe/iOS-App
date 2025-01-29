//
//  VPNManager+Selector.swift
//  Windscribe
//
//  Created by Thomas on 17/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
import Combine
import RxSwift
import Swinject

extension VPNManager {
    func simpleEnableConnection(isEmergency: Bool = false) {
        let nextProtocol = protocolManager.getProtocol()
        let locationID = locationsManager.getLastSelectedLocation()
        connectionTaskPublisher?.cancel()
        connectionTaskPublisher = connectFromViewModel(locationId: locationID, proto: nextProtocol, connectionType: .emergency)
            .sink { _ in } receiveValue: { _ in }
    }

    func simpleDisableConnection() {
        connectionTaskPublisher?.cancel()
        connectionTaskPublisher = disconnectFromViewModel()
            .sink { _ in } receiveValue: { _ in }
    }

    func resetProfiles() async {
        for manager in configManager.managers {
            await configManager.reset(manager: manager)
        }
    }

    // function to check if local ip belongs to RFC 1918 ips
    func checkLocalIPIsRFC() -> Bool {
        if let localIPAddress = NWInterface.InterfaceType.wifi.ipv4 {
            if localIPAddress.isRFC1918IPAddress {
                logger.logD(VPNManager.self, "It's an RFC1918 address. \(localIPAddress)")
                return true
            } else {
                logger.logD(VPNManager.self, "Non Rfc-1918 address found  \(localIPAddress)")
                return false
            }
        } else {
            logger.logD(VPNManager.self, "Failed to retrieve local IP address.")
            return true
        }
    }
}

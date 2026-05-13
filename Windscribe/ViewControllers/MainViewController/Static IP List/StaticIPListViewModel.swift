//
//  StaticIPListViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit
#if canImport(SafariServices)
    import SafariServices
#endif
import Combine

enum StaticIPAlertType {
    case connecting
    case disconnecting
    case underMaintananence
}

protocol StaticIPListFooterViewDelegate: AnyObject {
    func addStaticIP()
}

protocol StaticIPListViewModelType: StaticIPListFooterViewDelegate {
    var presentLinkTrigger: PassthroughSubject<URL, Never> { get }
    var presentAlertTrigger: PassthroughSubject<StaticIPAlertType, Never> { get }

    func setSelectedStaticIP(staticIP: StaticIPModel)
}

class StaticIPListViewModel: NSObject, StaticIPListViewModelType {
    let presentLinkTrigger = PassthroughSubject<URL, Never>()
    let presentAlertTrigger = PassthroughSubject<StaticIPAlertType, Never>()

    private let logger: FileLogger
    private let vpnStateRepository: VPNStateRepository
    private let connectivity: ConnectivityManager
    private let locationsManager: LocationsManager
    private let protocolManager: ProtocolManagerType

    init(logger: FileLogger,
         vpnStateRepository: VPNStateRepository,
         connectivity: ConnectivityManager,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType) {
        self.logger = logger
        self.vpnStateRepository = vpnStateRepository
        self.connectivity = connectivity
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
    }

    func setSelectedStaticIP(staticIP: StaticIPModel) {
        if !connectivity.internetConnectionAvailable() { return }

        if !staticIP.isActive {
            presentAlertTrigger.send(.underMaintananence)
            return
        }

        if vpnStateRepository.configurationState == ConfigurationState.disabling {
            presentAlertTrigger.send(.disconnecting)
            return
        }

        if vpnStateRepository.configurationState == ConfigurationState.initial {
            locationsManager.saveStaticIP(withId: staticIP.id)
            Task {
                self.logger.logI("StaticIPListViewModel", "setSelectedStaticIP for getNextProtocol")
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            presentAlertTrigger.send(.connecting)
        }
    }
}

extension StaticIPListViewModel: StaticIPListFooterViewDelegate {
    func addStaticIP() {
        logger.logD("StaticIPListViewModel", "User tapped Add Static IP button.")
        let urlString = LinkProvider.getWindscribeLink(path: Links.staticIPs)
        guard let url = URL(string: urlString) else { return }
        presentLinkTrigger.send(url)
    }
}

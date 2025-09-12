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
import RxSwift

enum StaticIPAlertType {
    case connecting
    case disconnecting
    case underMaintananence
}

protocol StaticIPListFooterViewDelegate: AnyObject {
    func addStaticIP()
}

protocol StaticIPListViewModelType: StaticIPListFooterViewDelegate {
    var presentLinkTrigger: PublishSubject<URL> { get }
    var presentAlertTrigger: PublishSubject<StaticIPAlertType> { get }

    func setSelectedStaticIP(staticIP: StaticIPModel)
}

class StaticIPListViewModel: NSObject, StaticIPListViewModelType {
    let presentLinkTrigger = PublishSubject<URL>()
    let presentAlertTrigger = PublishSubject<StaticIPAlertType>()

    private let logger: FileLogger
    private let vpnManager: VPNManager
    private let connectivity: Connectivity
    private let locationsManager: LocationsManager
    private let protocolManager: ProtocolManagerType

    init(logger: FileLogger,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType) {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
    }

    func setSelectedStaticIP(staticIP: StaticIPModel) {
        if !connectivity.internetConnectionAvailable() { return }

        if !staticIP.isActive {
            presentAlertTrigger.onNext(.underMaintananence)
            return
        }

        if vpnManager.configurationState == ConfigurationState.disabling {
            presentAlertTrigger.onNext(.disconnecting)
            return
        }

        if vpnManager.configurationState == ConfigurationState.initial {
            locationsManager.saveStaticIP(withID: staticIP.id)
            Task {
                await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: true)
            }
        } else {
            presentAlertTrigger.onNext(.connecting)
        }
    }
}

extension StaticIPListViewModel: StaticIPListFooterViewDelegate {
    func addStaticIP() {
        logger.logD("StaticIPListViewModel", "User tapped Add Static IP button.")
        let urlString = LinkProvider.getWindscribeLink(path: Links.staticIPs)
        guard let url = URL(string: urlString) else { return }
        presentLinkTrigger.onNext(url)
    }
}

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

enum StaticIPAlertType { case connecting; case disconnecting }

protocol StaticIPListFooterViewDelegate: AnyObject {
    func addStaticIP()
}

protocol StaticIPListViewModelType: StaticIPListFooterViewDelegate {
    var presentLinkTrigger: PublishSubject<URL> { get }
    var presentAlertTrigger: PublishSubject<StaticIPAlertType> { get }
    var configureVPNTrigger: PublishSubject<Void> { get }

    func setSelectedStaticIP(staticIP: StaticIPModel)
}

class StaticIPListViewModel: NSObject, StaticIPListViewModelType {
    let presentLinkTrigger = PublishSubject<URL>()
    let presentAlertTrigger = PublishSubject<StaticIPAlertType>()
    let configureVPNTrigger = PublishSubject<Void>()

    private let logger: FileLogger
    private let vpnManager: VPNManager
    private let connectivity: Connectivity
    private let locationsManager: LocationsManagerType

    init(logger: FileLogger, vpnManager: VPNManager, connectivity: Connectivity, locationsManager: LocationsManagerType) {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.locationsManager = locationsManager
    }

    func setSelectedStaticIP(staticIP: StaticIPModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnManager.isDisconnecting() {
            presentAlertTrigger.onNext(.disconnecting)
            return
        }

        if !vpnManager.isConnecting() {
            locationsManager.saveStaticIP(withID: staticIP.id)
            configureVPNTrigger.onNext(())
        } else {
            presentAlertTrigger.onNext(.connecting)
        }
    }
}

extension StaticIPListViewModel: StaticIPListFooterViewDelegate {
    func addStaticIP() {
        logger.logD(self, "User tapped Add Static IP button.")
        let urlString = LinkProvider.getWindscribeLink(path: Links.staticIPs)
        guard let url = URL(string: urlString) else { return }
        presentLinkTrigger.onNext(url)
    }
}

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
    var presentLinkTrigger = PublishSubject<URL>()
    var presentAlertTrigger = PublishSubject<StaticIPAlertType>()
    var configureVPNTrigger = PublishSubject<Void>()

    var logger: FileLogger
    var vpnManager: VPNManager
    var connectivity: Connectivity
    var preferences: Preferences

    init(logger: FileLogger, vpnManager: VPNManager, connectivity: Connectivity, preferences: Preferences) {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.preferences = preferences
    }

    func setSelectedStaticIP(staticIP: StaticIPModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnManager.isDisconnecting() {
            presentAlertTrigger.onNext(.disconnecting)
            return
        }


        // TODO: VPNManager revamp StaticIP
        if !vpnManager.isConnecting() {
            preferences.saveLastSelectedLocation(with: "static_\(staticIP.id ?? 0)")
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

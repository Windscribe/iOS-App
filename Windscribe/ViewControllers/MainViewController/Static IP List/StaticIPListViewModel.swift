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
    var connectionStateManager: ConnectionStateManagerType
    var connectivity: Connectivity

    init(logger: FileLogger,
         vpnManager: VPNManager,
         connectionStateManager: ConnectionStateManagerType, connectivity: Connectivity)
    {
        self.logger = logger
        self.vpnManager = vpnManager
        self.connectionStateManager = connectionStateManager
        self.connectivity = connectivity
    }

    func setSelectedStaticIP(staticIP: StaticIPModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnManager.isDisconnecting() {
            presentAlertTrigger.onNext(.disconnecting)

            return
        }
        if !connectionStateManager.isConnecting() {
            guard let node = staticIP.bestNode else { return }
            guard let staticIPN = staticIP.staticIP,
                  let countryCode = staticIP.countryCode,
                  let dnsHostname = node.dnsHostname,
                  let hostname = node.hostname, let serverAddress = node.ip2, let nickName = staticIP.staticIP, let cityName = staticIP.cityName, let credentials = staticIP.credentials else { return }
            logger.logD(self, "Tapped on Static IP \(staticIPN) from the server list.")
            vpnManager.selectedNode = SelectedNode(countryCode: countryCode,
                                                   dnsHostname: dnsHostname,
                                                   hostname: hostname,
                                                   serverAddress: serverAddress,
                                                   nickName: nickName,
                                                   cityName: cityName,
                                                   staticIPCredentials: credentials.last,
                                                   groupId: 0)

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

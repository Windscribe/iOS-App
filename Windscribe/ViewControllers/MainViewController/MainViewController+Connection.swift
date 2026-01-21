//
//  MainViewController+Connection.swift
//  Windscribe
//
//  Created by Thomas on 05/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import CoreLocation
import Foundation
import NetworkExtension
import UIKit
import Combine

extension MainViewController {
    func setNetworkSsid() {
        Publishers.CombineLatest(viewModel.updateSSIDTrigger, viewModel.appNetwork)
            .receive(on:DispatchQueue.main)
            .sink { [weak self] (_, network) in
                guard let self = self else { return }
                guard !self.vpnConnectionViewModel.isConnecting() else { return }
                guard !vpnConnectionViewModel.isNetworkCellularWhileConnecting(for: network) else { return }
                let locationStatus = self.locationPermissionManager.locationStatusSubject.value
                if locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways {
                    if network.networkType == .cellular || network.networkType == .wifi {
                        if let name = network.name {
                            self.wifiInfoView.updateWifiName(name: name)
                        }
                    } else {
                        self.wifiInfoView.updateWifiName(name: TextsAsset.NetworkSecurity.unknownNetwork)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

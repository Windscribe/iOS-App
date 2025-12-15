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
import RxSwift
import UIKit

extension MainViewController {
    func setNetworkSsid() {
        Observable.combineLatest(viewModel.updateSSIDTrigger, viewModel.appNetwork)
            .subscribe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (_, network) in
                guard let self = self else { return }
                guard !self.vpnConnectionViewModel.isConnecting() else { return }
                guard !vpnConnectionViewModel.isNetworkCellularWhileConnecting(for: network) else { return }
                if self.locationPermissionManager.getStatus() == .authorizedWhenInUse || self.locationPermissionManager.getStatus() == .authorizedAlways {
                    if network.networkType == .cellular || network.networkType == .wifi {
                        if let name = network.name {
                            self.wifiInfoView.updateWifiName(name: name)
                        }
                    } else {
                        self.wifiInfoView.updateWifiName(name: TextsAsset.NetworkSecurity.unknownNetwork)
                    }
                }
            }, onError: { [weak self] _ in
                self?.wifiInfoView.updateWifiName(name: TextsAsset.noNetworksAvailable)
            }).disposed(by: disposeBag)
    }
}

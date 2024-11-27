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
    @objc func trustedNetworkValueLabelTapped() {
        if trustedNetworkValueLabel.text == TextsAsset.NetworkSecurity.unknownNetwork {
            locationManagerViewModel.requestLocationPermission {
                self.setNetworkSsid()
            }
        } else {
            viewModel.markBlurNetworkName(isBlured: !viewModel.isBlurNetworkName)
            if viewModel.isBlurNetworkName {
                trustedNetworkValueLabel.isBlurring = true
            } else {
                trustedNetworkValueLabel.isBlurring = false
            }
        }
    }

    @objc func yourIPValueLabelTapped() {
        viewModel.markBlurStaticIpAddress(isBlured: !viewModel.isBlurStaticIpAddress)
        if viewModel.isBlurStaticIpAddress {
            yourIPValueLabel.isBlurring = true
        } else {
            yourIPValueLabel.isBlurring = false
        }
    }

    func renderBlurSpacedLabel() {
        if viewModel.isBlurNetworkName {
            trustedNetworkValueLabel.isBlurring = true
        } else {
            trustedNetworkValueLabel.isBlurring = false
        }
        if viewModel.isBlurStaticIpAddress {
            yourIPValueLabel.isBlurring = true
        } else {
            yourIPValueLabel.isBlurring = false
        }
    }

    func showSecureIPAddressState(ipAddress: String) {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else { return }
            self.yourIPValueLabel.text = ipAddress.formatIpAddress().maxLength(length: 15)
            if self.vpnConnectionViewModel.isConnected() {
                self.yourIPIcon.image = UIImage(named: ImagesAsset.secure)
            } else {
                self.yourIPIcon.image = UIImage(named: ImagesAsset.unsecure)
            }
        }
    }

    func setNetworkSsid() {
        viewModel.appNetwork.subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: { [self] network in
            if self.vpnConnectionViewModel.isConnecting() { return }
                if self.locationManagerViewModel.getStatus() == .authorizedWhenInUse || self.locationManagerViewModel.getStatus() == .authorizedAlways {
                    if network.networkType == .cellular || network.networkType == .wifi {
                        self.trustedNetworkValueLabel.text = network.name ?? ""
                    if let name = network.name {
                        self.trustedNetworkValueLabel.text = name
                    } else {
                        self.trustedNetworkValueLabel.text = TextsAsset.noNetworksAvailable
                        self.logger.logD(self, "no network name detected.")
                    }
                } else {
                    self.trustedNetworkValueLabel.text = TextsAsset.NetworkSecurity.unknownNetwork
                }
            }, onError: { [self] _ in
                self.trustedNetworkValueLabel.text = TextsAsset.noNetworksAvailable
            }).disposed(by: disposeBag)
    }
}

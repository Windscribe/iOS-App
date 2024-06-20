//
//  MainViewController+VPNManagerDelegate.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import NetworkExtension
import WidgetKit

extension MainViewController: VPNManagerDelegate {

    func showAutomaticModeFailedToConnectPopup() {
        LogManager.shared.log(activity: String(describing: MainViewController.self),
                              text: "Auto Mode couldn't find any protocol/port working.", type: .debug)
        openNetworkHateUsDialog()
    }

    func setDisconnected() {
        if loadLatencyValuesOnDisconnect {
            connectionStateViewModel.checkConnectedState()
            self.setConnectionLabelValues(nickName: "",
                                          cityName: TextsAsset.bestLocation)
            loadLatencyValuesOnDisconnect = false
            Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(loadLatencyValuesWithSelectAndConnectBestLocation), userInfo: nil, repeats: false)
        } else {
            self.connectionStateViewModel.checkConnectedState()
            self.ipAddressTimer?.invalidate()
            self.ipAddressTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.displayLocalIPAddress), userInfo: nil, repeats: false)
        }
        self.updateRefreshControls()
    }

    func setDisconnecting() {
        self.connectionStateViewModel.checkConnectedState()
        if self.vpnManager.userTappedToDisconnect { return }
        disconnectingStateTimer?.invalidate()
        disconnectingStateTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(setDisconnectingStateIfStillDisconnecting), userInfo: nil, repeats: false)
        self.updateRefreshControls()
    }

    func setConnectivityTest() {
        if self.vpnManager.isOnDemandRetry == true {
            connectionStateViewModel.updateToConnected()
            return
        }
        if self.vpnManager.userTappedToDisconnect { return }
        connectionStateViewModel.checkConnectedState()
        self.hideSplashView()
        self.updateRefreshControls()
        self.protocolSelectionChanged()
    }

    func setConnected(ipAddress: String) {
        if vpnManager.isOnDemandRetry == true {
            connectionStateViewModel.updateToConnected()
            return
        }
        if vpnManager.userTappedToDisconnect { return }
        connectionStateViewModel.checkConnectedState()
        showSecureIPAddressState(ipAddress: ipAddress)
        showPushNotificationPermissionPopupOnFirstConnection()
        showSiriPopupOnSecondConnection()
        updateRefreshControls()
    }

    func setConnecting() {
        if self.vpnManager.isOnDemandRetry == true {
            connectionStateViewModel.updateToConnected()
            return
        }
        if self.autoModeSelectorView.isHidden == true {
            connectionStateViewModel.checkConnectedState()
            self.updateRefreshControls()
        }
    }

    func setAutomaticModeFailed() {
        DispatchQueue.main.async { [weak self] in
            self?.connectionStateViewModel.updateToAutomaticModeFailed()
            self?.updateRefreshControls()
            self?.showAutoModeSelectorScreen()
        }

    }

    // TODO: Replace below Group Persistence Manager functions with those in SharedUserDefaults
    func saveDataForWidget() {
        if let cityName = self.vpnManager.selectedNode?.cityName, let nickName = self.vpnManager.selectedNode?.nickName, let countryCode = self.vpnManager.selectedNode?.countryCode {
            GroupPersistenceManager.shared.saveData(value: cityName, key: serverNameKey)
            GroupPersistenceManager.shared.saveData(value: nickName, key: nickNameKey)
            GroupPersistenceManager.shared.saveData(value: countryCode, key: countryCodeKey)
            if UserPreferencesManager.shared.selectedServerCredentialsType == IKEv2ServerCredentials.self {
                GroupPersistenceManager.shared.saveData(value: TextsAsset.iKEv2,
                                                        key: serverCredentialsTypeKey)
            } else {
                GroupPersistenceManager.shared.saveData(value: TextsAsset.openVPN,
                                                        key: serverCredentialsTypeKey)
            }
        }
        if #available(iOS 14.0, *) {
            #if arch(arm64) || arch(i386) || arch(x86_64)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }

    func displaySetPrefferedProtocol() {
        if let connectedWifi = WifiManager.shared.connectedWifi {
            if self.vpnManager.successfullProtocolChange == true && connectedWifi.preferredProtocolStatus == false {
                self.vpnManager.successfullProtocolChange = false
                DispatchQueue.main.async { [self] in
                    locationManagerViewModel.requestLocationPermission {
                        self.presentPreferredViewController()
                    }
                }
            }
        }
    }

    private func presentPreferredViewController() {
        router?.routeTo(to: RouteID.protocolSetPreferred(type: .connected, delegate: nil, protocolName: ConnectionManager.shared.getNextProtocol().protocolName), from: self)
    }

    private func showAutoModeSelectorScreen() {
        if let viewControllers = self.navigationController?.viewControllers {
            if viewControllers.contains(where: {
                return $0 is ProtocolSetPreferredViewController
            }) {
                return
            }
            if !viewControllers.contains(where: {
                return $0 is ProtocolSwitchViewController
            }) {
                router?.routeTo(to: RouteID.protocolSwitchVC(delegate: self, type: .failure), from: self)
            }
        }
    }

    func disconnectVpn() {
        self.disconnect()
    }
}

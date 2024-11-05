//
//  MainViewController+VPNManagerDelegate.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import UIKit
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
            setConnectionLabelValues(nickName: "",
                                     cityName: TextsAsset.bestLocation)
            loadLatencyValuesOnDisconnect = false
            Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(loadLatencyValuesWithSelectAndConnectBestLocation), userInfo: nil, repeats: false)
        } else {
            connectionStateViewModel.checkConnectedState()
            ipAddressTimer?.invalidate()
            ipAddressTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(displayLocalIPAddress), userInfo: nil, repeats: false)
        }
        updateRefreshControls()
    }

    func setDisconnecting() {
        connectionStateViewModel.checkConnectedState()
        if vpnManager.userTappedToDisconnect { return }
        disconnectingStateTimer?.invalidate()
        disconnectingStateTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(setDisconnectingStateIfStillDisconnecting), userInfo: nil, repeats: false)
        updateRefreshControls()
    }

    func setConnectivityTest() {
        if vpnManager.isOnDemandRetry == true {
            connectionStateViewModel.updateToConnected()
            return
        }
        if vpnManager.userTappedToDisconnect { return }
        connectionStateViewModel.checkConnectedState()
        hideSplashView()
        updateRefreshControls()
        protocolSelectionChanged()
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
        if vpnManager.isOnDemandRetry == true {
            connectionStateViewModel.updateToConnected()
            return
        }
        if autoModeSelectorView.isHidden == true {
            connectionStateViewModel.checkConnectedState()
            updateRefreshControls()
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
        if let cityName = vpnManager.selectedNode?.cityName, let nickName = vpnManager.selectedNode?.nickName, let countryCode = vpnManager.selectedNode?.countryCode {
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
            if vpnManager.successfullProtocolChange == true && connectedWifi.preferredProtocolStatus == false {
                vpnManager.successfullProtocolChange = false
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
        if let viewControllers = navigationController?.viewControllers {
            if viewControllers.contains(where: {
                $0 is ProtocolSetPreferredViewController
            }) {
                return
            }
            if !viewControllers.contains(where: {
                $0 is ProtocolSwitchViewController
            }) {
                router?.routeTo(to: RouteID.protocolSwitchVC(delegate: self, type: .failure), from: self)
            }
        }
    }

    func disconnectVpn() {
        disconnect()
    }
}

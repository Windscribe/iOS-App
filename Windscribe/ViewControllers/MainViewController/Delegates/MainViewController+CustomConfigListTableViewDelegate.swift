//
//  MainViewController+CustomConfigListTableViewDelegate.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import MobileCoreServices
import UIKit

extension MainViewController: CustomConfigListTableViewDelegate {
    func addCustomConfigAction() {
        LogManager.shared.log(
            activity: String(describing: MainViewController.self),
            text: "User tapped Add Custom Config button.",
            type: .debug
        )
        let documentTypes = ["com.windscribe.wireguard.config.quick",
                             String(kUTTypeText)]
        let filePicker = UIDocumentPickerViewController(documentTypes: documentTypes,
                                                        in: .import)
        filePicker.delegate = self
        present(filePicker, animated: true)
    }

    func setSelectedCustomConfig(customConfig: CustomConfigModel) {
        if !ReachabilityManager.shared.internetConnectionAvailable() { return }
        if vpnManager.isDisconnecting() { displayDisconnectingAlert(); return }
        if !vpnManagerViewModel.isConnecting() {
            LogManager.shared.log(activity: String(describing: MainViewController.self), text: "Tapped on Custom config from the list.", type: .debug)

            guard let name = customConfig.name, let serverAddress = customConfig.serverAddress else { return }

            vpnManager.selectedNode = SelectedNode(countryCode: Fields.configuredLocation,
                                                   dnsHostname: serverAddress,
                                                   hostname: serverAddress,
                                                   serverAddress: serverAddress,
                                                   nickName: name,
                                                   cityName: TextsAsset.configuredLocation,
                                                   customConfig: customConfig,
                                                   groupId: 0)
            if (customConfig.username == "" || customConfig.password == "") && (customConfig.authRequired ?? false) {
                customConfigStateManager.setCurrentConfig(customConfig, isUpdating: false)
                popupRouter?.routeTo(to: .enterCredentials, from: self)
            } else {
                configureVPN()
            }
        } else {
            displayConnectingAlert()
        }
    }

    func showRemoveAlertForCustomConfig(id: String, protocolType: String) {
        let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { _ in
            if protocolType == wireGuard {
                self.customConfigRepository?.removeWgConfig(fileId: id)
            } else {
                self.customConfigRepository?.removeOpenVPNConfig(fileId: id)
            }
            if self.vpnManager.selectedNode?.customConfig?.id == id {
                self.resetConnectionStatus()
            }
        }
        AlertManager.shared.showAlert(title: TextsAsset.RemoveCustomConfig.title,
                                      message: TextsAsset.RemoveCustomConfig.message,
                                      buttonText: TextsAsset.cancel,
                                      actions: [yesAction])
    }

    private func resetConnectionStatus() {
        if vpnManager.isActive {
            LogManager.shared.log(activity: String(describing: MainViewController.self),
                                  text: "Disconnecting from selected custom config.",
                                  type: .debug)
            vpnManager.disconnectActiveVPNConnection()
        }
        setBestLocation()
    }

    private func setBestLocation() {
        guard let bestLocation = PersistenceManager.shared.retrieve(type: BestLocation.self)?.first else { return }
        if !vpnManagerViewModel.isConnecting() {
            LogManager.shared.log(activity: String(describing: MainViewController.self),
                                  text: "Changing selected location to Best location with hostname \(bestLocation.hostname)",
                                  type: .debug)
            vpnManager.selectedNode = SelectedNode(countryCode: bestLocation.countryCode,
                                                   dnsHostname: bestLocation.dnsHostname,
                                                   hostname: bestLocation.hostname,
                                                   serverAddress: bestLocation.ipAddress,
                                                   nickName: bestLocation.nickName,
                                                   cityName: bestLocation.cityName,
                                                   groupId: bestLocation.groupId)
        }
    }

    func showEditCustomConfig(customConfig: CustomConfigModel) {
        customConfigStateManager.setCurrentConfig(customConfig, isUpdating: true)
        popupRouter?.routeTo(to: .enterCredentials, from: self)
    }

    func hideCustomConfigRefreshControl() {
        if customConfigTableView.subviews.contains(customConfigsTableViewRefreshControl) {
            customConfigsTableViewRefreshControl.removeFromSuperview()
        }
        customConfigTableViewFooterView.isHidden = true
    }

    func showCustomConifgRefreshControl() {
        if !customConfigTableView.subviews.contains(customConfigsTableViewRefreshControl) {
            customConfigTableView.addSubview(customConfigsTableViewRefreshControl)
        }
        customConfigTableViewFooterView.isHidden = false
    }

    func setAutoModeSelectorOverlayFocus(button: UIButton, selectedProtocol: String) {
        UIView.animate(withDuration: 0.35) {
            self.autoModeSelectorOverlayView.center.x = button.center.x
            self.autoModeSelectorOverlayView.center.y = button.center.y
            self.selectedNextProtocol = selectedProtocol
        }
    }

    @objc func hideAutoModeSelectorView(connect: Bool = false) {
        showGetMoreDataViews()

        autoModeSelectorViewTimer?.invalidate()
        UIView.animate(withDuration: 1.0, animations: {
            self.autoModeSelectorView.frame = CGRect(x: 16, y: self.view.frame.maxY + 100, width: self.view.frame.width - 32, height: 44)
        }, completion: { _ in
            self.autoModeSelectorView.isHidden = true
            if connect {
                self.vpnManager.connectUsingAutomaticMode()
            }
        })
    }

    @objc func updateAutoModeSelectorCounter() {
        guard let counter = autoModeSelectorCounterLabel.text else { return }
        let nextCount = Int(counter)! - 1
        autoModeSelectorCounterLabel.text = "\(nextCount)"
        if nextCount == 0 {
            hideAutoModeSelectorView(connect: true)
        }
    }

    @objc func autoModeProtocolButtonTapped(sender: UIButton) {
        switch sender {
        case autoModeSelectorIkev2Button:
            setAutoModeSelectorOverlayFocus(button: sender, selectedProtocol: iKEv2)
        case autoModeSelectorUDPButton:
            setAutoModeSelectorOverlayFocus(button: sender, selectedProtocol: udp)
        case autoModeSelectorTCPButton:
            setAutoModeSelectorOverlayFocus(button: sender, selectedProtocol: tcp)
        default:
            return
        }
    }
}

//
//  CustomConfigPickerViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 03/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import MobileCoreServices

enum ConfigAlertType {
    case connecting
    case disconnecting
}

protocol CustomConfigPickerDelegate: AnyObject {
}

protocol AddCustomConfigDelegate: AnyObject {
    func addCustomConfig()
}

protocol CustomConfigPickerViewModelType: CustomConfigListModelDelegate {
    var displayAllertTrigger: PublishSubject<ConfigAlertType> { get }
    var configureVPNTrigger: PublishSubject<Void> { get }
    var presentDocumentPickerTrigger: PublishSubject<UIDocumentPickerViewController> { get }
    var showEditCustomConfigTrigger: PublishSubject<(customConfig: CustomConfigModel, isUpdating: Bool)> { get }
}

class CustomConfigPickerViewModel: NSObject, CustomConfigPickerViewModelType {
    var logger: FileLogger
    var alertManager: AlertManagerV2
    var customConfigRepository: CustomConfigRepository
    var vpnManager: VPNManager
    var localDataBase: LocalDatabase
    var connectivity: Connectivity
    var connectionStateManager: ConnectionStateManagerType

    var displayAllertTrigger = PublishSubject<ConfigAlertType>()
    var configureVPNTrigger = PublishSubject<Void>()
    var presentDocumentPickerTrigger = PublishSubject<UIDocumentPickerViewController>()
    var showEditCustomConfigTrigger = PublishSubject<(customConfig: CustomConfigModel, isUpdating: Bool)>()

    let disposeBag = DisposeBag()

    init(logger: FileLogger,
         alertManager: AlertManagerV2,
         customConfigRepository: CustomConfigRepository,
         vpnManager: VPNManager,
         localDataBase: LocalDatabase,
         connectionStateManager: ConnectionStateManagerType,
         connectivity: Connectivity
    ) {
        self.logger = logger
        self.alertManager = alertManager
        self.customConfigRepository = customConfigRepository
        self.vpnManager = vpnManager
        self.localDataBase = localDataBase
        self.connectionStateManager = connectionStateManager
        self.connectivity = connectivity
    }
}

extension CustomConfigPickerViewModel: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        logger.logD(self, "Importing WireGuard/OpenVPN .conf file")
        let fileName = url.lastPathComponent.replacingOccurrences(of: ".\(url.pathExtension)", with: "")
        localDataBase.getCustomConfig().take(1).subscribe(on: MainScheduler.instance).subscribe(onNext: {
            let config = $0.first {
                return $0.name == fileName
            }
            if config != nil {
                self.alertManager.showSimpleAlert(viewController: nil, title: TextsAsset.error, message: TextsAsset.customConfigWithSameFileNameError, buttonText: TextsAsset.okay)
                return
            }
            if url.isFileURL && url.pathExtension == "ovpn" {
                _ = self.customConfigRepository.saveOpenVPNConfig(url: url)
            } else if url.isFileURL && url.pathExtension == "conf" {
                _ = self.customConfigRepository.saveWgConfig(url: url)
            }
        }).disposed(by: disposeBag)
    }
}

extension CustomConfigPickerViewModel: AddCustomConfigDelegate {
    func addCustomConfig() {
        logger.logD(self, "User tapped to Add Custom Config")

        let documentTypes = ["com.windscribe.wireguard.config.quick",String(kUTTypeText)]
        let filePicker = UIDocumentPickerViewController(documentTypes: documentTypes,in: .import)
        filePicker.delegate = self
        presentDocumentPickerTrigger.onNext(filePicker)
    }
}

extension CustomConfigPickerViewModel: CustomConfigListModelDelegate {
    func setSelectedCustomConfig(customConfig: CustomConfigModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnManager.isDisconnecting() {
            displayAllertTrigger.onNext(.disconnecting)
            return
        }
        self.continueSetSelected(with: customConfig, and: connectionStateManager.isConnecting())
    }

    func showRemoveAlertForCustomConfig(id: String, protocolType: String) {
        let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { _ in
            if protocolType == wireGuard {
                self.customConfigRepository.removeWgConfig(fileId: id)
            } else {
                self.customConfigRepository.removeOpenVPNConfig(fileId: id)
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

    func showEditCustomConfig(customConfig: CustomConfigModel) {
        showEditCustomConfigTrigger.onNext((customConfig: customConfig, isUpdating: true))
    }

    private func continueSetSelected(with customConfig: CustomConfigModel, and isConnecting: Bool) {
        if isConnecting {
            self.displayAllertTrigger.onNext(.connecting)
            return
        }

        logger.logD(self, "Tapped on Custom config from the list.")
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
            showEditCustomConfigTrigger.onNext((customConfig: customConfig, isUpdating: false))
            return
        }

        configureVPNTrigger.onNext(())
    }

    private func resetConnectionStatus() {
        if vpnManager.isActive {
            logger.logD(self, "Disconnecting from selected custom config.")
            vpnManager.disconnectActiveVPNConnection()
        }
        self.setBestLocation()
    }

    private func setBestLocation() {
        localDataBase.getBestLocation().take(1).subscribe(on: MainScheduler.instance).subscribe(onNext: { bestLocation in
            if self.connectionStateManager.isConnecting() { self.logger.logD(self, "Changing selected location to Best location with hostname \(bestLocation.hostname)")
                self.vpnManager.selectedNode = SelectedNode(countryCode: bestLocation.countryCode,
                                                            dnsHostname: bestLocation.dnsHostname,
                                                            hostname: bestLocation.hostname,
                                                            serverAddress: bestLocation.ipAddress,
                                                            nickName: bestLocation.nickName,
                                                            cityName: bestLocation.cityName,
                                                            groupId: bestLocation.groupId)
            }
        }).disposed(by: disposeBag)
    }
}

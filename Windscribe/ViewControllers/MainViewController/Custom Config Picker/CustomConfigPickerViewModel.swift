//
//  CustomConfigPickerViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 03/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import MobileCoreServices
import RxSwift
import UIKit

enum ConfigAlertType {
    case connecting
    case disconnecting
}

protocol CustomConfigPickerDelegate: AnyObject {}

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
    let logger: FileLogger
    let alertManager: AlertManagerV2
    let customConfigRepository: CustomConfigRepository
    let vpnManager: VPNManager
    let localDataBase: LocalDatabase
    let connectivity: Connectivity
    let preferences: Preferences
    let locationsManager: LocationsManagerType

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
         connectivity: Connectivity,
         preferences: Preferences,
         locationsManager: LocationsManagerType)
    {
        self.logger = logger
        self.alertManager = alertManager
        self.customConfigRepository = customConfigRepository
        self.vpnManager = vpnManager
        self.localDataBase = localDataBase
        self.connectivity = connectivity
        self.preferences = preferences
        self.locationsManager = locationsManager
    }
}

extension CustomConfigPickerViewModel: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        logger.logD(self, "Importing WireGuard/OpenVPN .conf file")
        let fileName = url.lastPathComponent.replacingOccurrences(of: ".\(url.pathExtension)", with: "")
        localDataBase.getCustomConfig().take(1).subscribe(on: MainScheduler.instance).subscribe(onNext: {
            let config = $0.first { $0.name == fileName }
            if config != nil {
                self.alertManager.showSimpleAlert(viewController: nil, title: TextsAsset.error, message: TextsAsset.customConfigWithSameFileNameError, buttonText: TextsAsset.okay)
                return
            }
            if url.isFileURL, url.pathExtension == "ovpn" {
                _ = self.customConfigRepository.saveOpenVPNConfig(url: url)
            } else if url.isFileURL, url.pathExtension == "conf" {
                _ = self.customConfigRepository.saveWgConfig(url: url)
            }
        }).disposed(by: disposeBag)
    }
}

extension CustomConfigPickerViewModel: AddCustomConfigDelegate {
    func addCustomConfig() {
        logger.logD(self, "User tapped to Add Custom Config")

        let documentTypes = ["com.windscribe.wireguard.config.quick", "org.openvpn.config", "public.data", String(kUTTypeText)]
        let filePicker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
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
        continueSetSelected(with: customConfig, and: vpnManager.isConnecting())
    }

    func showRemoveAlertForCustomConfig(id: String, protocolType: String) {
        let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { _ in
            if protocolType == wireGuard {
                self.customConfigRepository.removeWgConfig(fileId: id)
            } else {
                self.customConfigRepository.removeOpenVPNConfig(fileId: id)
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
        logger.logD(self, "Tapped on Custom config from the list.")

        guard !isConnecting else {
            displayAllertTrigger.onNext(.connecting)
            return
        }

        locationsManager.saveLastSelectedLocation(with: "custom_\(customConfig.id ?? "0")")
        if (customConfig.username == "" || customConfig.password == "") && (customConfig.authRequired ?? false) {
            showEditCustomConfigTrigger.onNext((customConfig: customConfig, isUpdating: false))
            return
        }
        configureVPNTrigger.onNext(())
    }

    private func resetConnectionStatus() {
        Task {
            if await vpnManager.isActive() {
                logger.logD(self, "Disconnecting from selected custom config.")
                vpnManager.disconnectActiveVPNConnection()
            }
        }
        setBestLocation()
    }

    private func setBestLocation() {
        let locationID = locationsManager.getBestLocation()
        if !locationID.isEmpty, locationID != "0", !self.vpnManager.isConnecting() {
            self.logger.logD(self, "Changing selected location to Best location ID \(locationID) from the server list.")
            self.locationsManager.selectBestLocation(with: locationID)
            self.configureVPNTrigger.onNext(())
        } else {
            self.locationsManager.saveBestLocation(with: "")
        }
    }
}

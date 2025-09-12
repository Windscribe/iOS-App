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
import UniformTypeIdentifiers

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
    var disableVPNTrigger: PublishSubject<Void> { get }
    var presentDocumentPickerTrigger: PublishSubject<UIDocumentPickerViewController> { get }
    var showEditCustomConfigTrigger: PublishSubject<CustomConfigModel> { get }
}

class CustomConfigPickerViewModel: NSObject, CustomConfigPickerViewModelType {
    let logger: FileLogger
    let alertManager: AlertManagerV2
    let customConfigRepository: CustomConfigRepository
    let vpnManager: VPNManager
    let localDataBase: LocalDatabase
    let connectivity: ConnectivityManager
    let locationsManager: LocationsManager
    let protocolManager: ProtocolManagerType

    var displayAllertTrigger = PublishSubject<ConfigAlertType>()
    var configureVPNTrigger = PublishSubject<Void>()
    var disableVPNTrigger = PublishSubject<Void>()
    var presentDocumentPickerTrigger = PublishSubject<UIDocumentPickerViewController>()
    var showEditCustomConfigTrigger = PublishSubject<CustomConfigModel>()

    let disposeBag = DisposeBag()

    init(logger: FileLogger,
         alertManager: AlertManagerV2,
         customConfigRepository: CustomConfigRepository,
         vpnManager: VPNManager,
         localDataBase: LocalDatabase,
         connectivity: ConnectivityManager,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType) {
        self.logger = logger
        self.alertManager = alertManager
        self.customConfigRepository = customConfigRepository
        self.vpnManager = vpnManager
        self.localDataBase = localDataBase
        self.connectivity = connectivity
        self.locationsManager = locationsManager
        self.protocolManager = protocolManager
    }
}

extension CustomConfigPickerViewModel: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard !urls.isEmpty else { return }
        logger.logD("CustomConfigPickerViewModel", "Importing WireGuard/OpenVPN .conf file")
        urls.forEach { url in
            let fileName = url.lastPathComponent.replacingOccurrences(of: ".\(url.pathExtension)", with: "")
            localDataBase.getCustomConfig().take(1).subscribe(on: MainScheduler.instance).subscribe(onNext: {
                let config = $0.first { $0.name == fileName }
                if config != nil {
                    self.alertManager.showSimpleAlert(viewController: nil, title: TextsAsset.error, message: TextsAsset.customConfigWithSameFileNameError, buttonText: TextsAsset.okay)
                    return
                }
                guard url.startAccessingSecurityScopedResource() else {
                    self.logger.logI("CustomConfigPickerViewModel", "Error when accessing config file")
                    return
                }
                if url.isFileURL, url.pathExtension == "ovpn" {
                    _ = self.customConfigRepository.saveOpenVPNConfig(url: url)
                } else if url.isFileURL, url.pathExtension == "conf" {
                    _ = self.customConfigRepository.saveWgConfig(url: url)
                }

                url.stopAccessingSecurityScopedResource()
            }).disposed(by: disposeBag)
        }
    }
}

extension CustomConfigPickerViewModel: AddCustomConfigDelegate {
    func addCustomConfig() {
        logger.logD("CustomConfigPickerViewModel", "User tapped to Add Custom Config")

        let documentTypes: [UTType] = [
            UTType("com.windscribe.wireguard.config.quick") ?? .data,
            UTType("org.openvpn.config") ?? .data,
            UTType.data,
            UTType.text
        ]

        let filePicker = UIDocumentPickerViewController(forOpeningContentTypes: documentTypes)
        filePicker.delegate = self
        filePicker.allowsMultipleSelection = true
        presentDocumentPickerTrigger.onNext(filePicker)
    }
}

extension CustomConfigPickerViewModel: CustomConfigListModelDelegate {
    func setSelectedCustomConfig(customConfig: CustomConfigModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnManager.configurationState == ConfigurationState.disabling {
            displayAllertTrigger.onNext(.disconnecting)
            return
        }
        Task { @MainActor in
            await continueSetSelected(with: customConfig, and: vpnManager.isConnecting())
        }
    }

    func showRemoveAlertForCustomConfig(id: String, protocolType: String) {
        let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { _ in
            if protocolType == wireGuard {
                self.customConfigRepository.removeWgConfig(fileId: id)
            } else {
                self.customConfigRepository.removeOpenVPNConfig(fileId: id)
            }
            if self.locationsManager.getLastSelectedLocation() == id {
                self.resetConnectionStatus()
            }
        }
        AlertManager.shared.showAlert(title: TextsAsset.RemoveCustomConfig.title,
                                      message: TextsAsset.RemoveCustomConfig.message,
                                      buttonText: TextsAsset.cancel,
                                      actions: [yesAction])
    }

    func showEditCustomConfig(customConfig: CustomConfigModel) {
        showEditCustomConfigTrigger.onNext(customConfig)
    }

    private func continueSetSelected(with customConfig: CustomConfigModel, and isConnecting: Bool) async {
        logger.logD("CustomConfigPickerViewModel", "Tapped on Custom config from the list.")

        guard !isConnecting else {
            displayAllertTrigger.onNext(.connecting)
            return
        }

        locationsManager.saveCustomConfig(withID: customConfig.id)
        configureVPNTrigger.onNext(())
    }

    private func resetConnectionStatus() {
        disableVPNTrigger.onNext(())
        setBestLocation()
    }

    private func setBestLocation() {
        let locationID = locationsManager.getBestLocation()
        if !locationID.isEmpty, locationID != "0", !self.vpnManager.isConnecting() {
            self.logger.logD("CustomConfigPickerViewModel", "Changing selected location to Best location ID \(locationID) from the server list.")
            self.locationsManager.saveLastSelectedLocation(with: locationID)
            self.configureVPNTrigger.onNext(())
        } else {
            self.locationsManager.saveBestLocation(with: "")
        }
    }
}

//
//  CustomConfigPickerViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 03/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import MobileCoreServices
import Combine
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
    var displayAllertTrigger: PassthroughSubject<ConfigAlertType, Never> { get }
    var configureVPNTrigger: PassthroughSubject<Void, Never> { get }
    var disableVPNTrigger: PassthroughSubject<Void, Never> { get }
    var presentDocumentPickerTrigger: PassthroughSubject<UIDocumentPickerViewController, Never> { get }
    var showEditCustomConfigTrigger: PassthroughSubject<CustomConfigModel, Never> { get }
}

class CustomConfigPickerViewModel: NSObject, CustomConfigPickerViewModelType {
    let logger: FileLogger
    let alertManager: AlertManager
    let customConfigRepository: CustomConfigRepository
    let vpnStateRepository: VPNStateRepository
    let connectivity: ConnectivityManager
    let locationsManager: LocationsManager
    let protocolManager: ProtocolManagerType

    var displayAllertTrigger = PassthroughSubject<ConfigAlertType, Never>()
    var configureVPNTrigger = PassthroughSubject<Void, Never>()
    var disableVPNTrigger = PassthroughSubject<Void, Never>()
    var presentDocumentPickerTrigger = PassthroughSubject<UIDocumentPickerViewController, Never>()
    var showEditCustomConfigTrigger = PassthroughSubject<CustomConfigModel, Never>()

    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger,
         alertManager: AlertManager,
         customConfigRepository: CustomConfigRepository,
         vpnStateRepository: VPNStateRepository,
         connectivity: ConnectivityManager,
         locationsManager: LocationsManager,
         protocolManager: ProtocolManagerType) {
        self.logger = logger
        self.alertManager = alertManager
        self.customConfigRepository = customConfigRepository
        self.vpnStateRepository = vpnStateRepository
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
            customConfigRepository.customConfigs
                .prefix(1)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] customConfigs in
                    guard let self = self else { return }
                    let config = customConfigs.first { $0.name == fileName }
                    if config != nil {
                        self.alertManager.showSimpleAlert(viewController: nil, title: TextsAsset.error, message: TextsAsset.customConfigWithSameFileNameError, buttonText: TextsAsset.okay)
                        return
                    }
                    guard url.startAccessingSecurityScopedResource() else {
                        self.logger.logI("CustomConfigPickerViewModel", "Error when accessing config file")
                        return
                    }
                    if url.isFileURL, url.pathExtension == "ovpn" {
                        Task {
                            do {
                                try await self.customConfigRepository.saveOpenVPNConfig(url: url)
                                url.stopAccessingSecurityScopedResource()
                            } catch {
                                await self.showCustomConfigError(with: error)
                            }
                        }
                    } else if url.isFileURL, url.pathExtension == "conf" {
                        Task {
                            do {
                                try await self.customConfigRepository.saveWgConfig(url: url)
                                url.stopAccessingSecurityScopedResource()
                            } catch {
                                await self.showCustomConfigError(with: error)
                            }
                        }
                    }
                }
                .store(in: &cancellables)
        }
    }

    @MainActor
    private func showCustomConfigError(with error: Error) async {
        if let error = error as? RepositoryError {
            await MainActor.run {
                alertManager.showSimpleAlert(title: TextsAsset.error, message: error.description, buttonText: TextsAsset.okay)
            }
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
        presentDocumentPickerTrigger.send(filePicker)
    }
}

extension CustomConfigPickerViewModel: CustomConfigListModelDelegate {
    func setSelectedCustomConfig(customConfig: CustomConfigModel) {
        if !connectivity.internetConnectionAvailable() { return }
        if vpnStateRepository.configurationState == ConfigurationState.disabling {
            displayAllertTrigger.send(.disconnecting)
            return
        }
        Task { @MainActor in
            await continueSetSelected(with: customConfig, and: vpnStateRepository.isConnecting())
        }
    }

    func showRemoveAlertForCustomConfig(id: String, protocolType: String) {
        let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { _ in
            Task {
                if protocolType == VPNProtocolType.wireGuard.identifier {
                    await self.customConfigRepository.removeWgConfig(fileId: id)
                } else {
                    await self.customConfigRepository.removeOpenVPNConfig(fileId: id)
                }
            }
            if self.locationsManager.getLastConnectionTarget() == id {
                self.resetConnectionStatus()
            }
        }
        alertManager.showAlert(title: TextsAsset.RemoveCustomConfig.title,
                                      message: TextsAsset.RemoveCustomConfig.message,
                                      buttonText: TextsAsset.cancel,
                                      actions: [yesAction])
    }

    func showEditCustomConfig(customConfig: CustomConfigModel) {
        showEditCustomConfigTrigger.send(customConfig)
    }

    private func continueSetSelected(with customConfig: CustomConfigModel, and isConnecting: Bool) async {
        logger.logD("CustomConfigPickerViewModel", "Tapped on Custom config from the list.")

        guard !isConnecting else {
            displayAllertTrigger.send(.connecting)
            return
        }

        locationsManager.saveCustomConfig(withId: customConfig.id)
        configureVPNTrigger.send(())
    }

    private func resetConnectionStatus() {
        disableVPNTrigger.send(())
        setBestLocation()
    }

    private func setBestLocation() {
        let locationID = locationsManager.getBestLocation()
        if locationID != 0, !self.vpnStateRepository.isConnecting() {
            self.logger.logD("CustomConfigPickerViewModel", "Changing selected location to Best location ID \(locationID) from the server list.")
            self.locationsManager.saveLastConnectionTarget(with: String(locationID))
            self.configureVPNTrigger.send(())
        } else {
            self.locationsManager.saveBestLocation(with: "")
        }
    }
}

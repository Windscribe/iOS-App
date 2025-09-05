//
//  ConnectionSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UserNotifications
import UIKit
import RxSwift

protocol ConnectionSettingsViewModel: PreferencesBaseViewModel {
    var entries: [ConnectionsEntryType] { get set }
    var safariURL: URL? { get }
    var router: ConnectionsNavigationRouter { get }

    func entrySelected(_ entry: ConnectionsEntryType, action: MenuEntryActionResponseType)
}

class ConnectionSettingsViewModelImpl: PreferencesBaseViewModelImpl, ConnectionSettingsViewModel {
    @Published var entries: [ConnectionsEntryType] = []
    @Published var safariURL: URL?
    @Published var router: ConnectionsNavigationRouter

    private var currentProtocol = DefaultValues.protocol
    private var currentPort = DefaultValues.port
    private var killSwitchSelected = DefaultValues.killSwitch
    private var allowLanSelected = DefaultValues.allowLANMode
    private var circumventCensorshipSelected = DefaultValues.circumventCensorship

    private var connectionMode = DefaultValues.connectionMode
    private var connectedDNS = DefaultValues.connectedDNS

    // MARK: - Dependencies
    private let preferences: Preferences
    private let localDatabase: LocalDatabase
    private let protocolManager: ProtocolManagerType

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         preferences: Preferences,
         localDatabase: LocalDatabase,
         router: ConnectionsNavigationRouter,
         protocolManager: ProtocolManagerType) {
        self.preferences = preferences
        self.localDatabase = localDatabase
        self.router = router
        self.protocolManager = protocolManager

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)
    }

    override func bindSubjects() {
        super.bindSubjects()

        preferences.getSelectedProtocol()
            .toPublisher(initialValue: DefaultValues.protocol)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ConnectionSettingsViewModel", "Preferred Protocol error: \(error)")
                }
            }, receiveValue: { [weak self] preferredProtocol in
                guard let self = self else { return }
                self.currentProtocol = preferredProtocol ?? DefaultValues.protocol
                self.reloadItems()
            })
            .store(in: &cancellables)

        preferences.getSelectedPort()
            .toPublisher(initialValue: DefaultValues.port)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ConnectionSettingsViewModel", "Preferred Port error: \(error)")
                }
            }, receiveValue: { [weak self] port in
                guard let self = self else { return }
                self.currentPort = port ?? DefaultValues.port
                self.reloadItems()
            })
            .store(in: &cancellables)

        preferences.getKillSwitch()
            .toPublisher(initialValue: DefaultValues.killSwitch)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ConnectionSettingsViewModel", "Kill Switch error: \(error)")
                }
            }, receiveValue: { [weak self] enabled in
                guard let self = self else { return }
                self.killSwitchSelected = enabled ?? DefaultValues.killSwitch
                self.reloadItems()
            })
            .store(in: &cancellables)

        preferences.getAllowLAN()
            .toPublisher(initialValue: DefaultValues.allowLANMode)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ConnectionSettingsViewModel", "Allow LAN error: \(error)")
                }
            }, receiveValue: { [weak self] enabled in
                guard let self = self else { return }
                self.allowLanSelected = enabled ?? DefaultValues.allowLANMode
                self.reloadItems()
            })
            .store(in: &cancellables)

        preferences.getCircumventCensorshipEnabled()
            .toPublisher(initialValue: DefaultValues.circumventCensorship)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ConnectionSettingsViewModel", "Circumvent Censorship error: \(error)")
                }
            }, receiveValue: { [weak self] enabled in
                guard let self = self else { return }
                self.circumventCensorshipSelected = enabled
                self.reloadItems()
            })
            .store(in: &cancellables)

        preferences.getConnectionMode()
            .toPublisher(initialValue: DefaultValues.connectionMode)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ConnectionSettingsViewModel", "Connection Mode error: \(error)")
                }
            }, receiveValue: { [weak self] mode in
                guard let self = self else { return }
                self.connectionMode = (mode ?? DefaultValues.connectionMode).localized
                self.reloadItems()
            })
            .store(in: &cancellables)

        preferences.getConnectedDNSObservable()
            .toPublisher(initialValue: DefaultValues.connectedDNS)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ConnectionSettingsViewModel", "Connected DNS error: \(error)")
                }
            }, receiveValue: { [weak self] mode in
                guard let self = self else { return }
                self.connectedDNS = (mode ?? DefaultValues.connectedDNS).localized
                self.reloadItems()
            })
            .store(in: &cancellables)
    }

    override func reloadItems() {
        let customDNSValue = preferences.getCustomDNSValue().value
        let connectionModes = zip(TextsAsset.connectionModes,
                                  Fields.connectionModes)
            .map { MenuOption(title: $0, fieldKey: $1) }
        let connectedDNSOptions = zip(TextsAsset.connectedDNSOptions,
                                      Fields.connectedDNSOptions)
            .map { MenuOption(title: $0, fieldKey: $1) }

        let protocolOptions = getProtocols()
            .map { MenuOption(title: $0, fieldKey: $0) }
        let portOptions = getPorts(by: currentProtocol)
            .map { MenuOption(title: $0, fieldKey: $0) }

        entries = [
            .networkOptions,
            .connectionMode(currentOption: connectionMode,
                            options: connectionModes,
                            protocolSelected: currentProtocol,
                            protocolOptions: protocolOptions,
                            portSelected: currentPort,
                            portOptions: portOptions)]
        if currentProtocol != TextsAsset.iKEv2 || connectionMode == Fields.Values.auto {
            entries.append(.connectedDns(currentOption: connectedDNS,
                                         customValue: customDNSValue,
                                         options: connectedDNSOptions))
        }
        entries.append(contentsOf: [.alwaysOn(isSelected: killSwitchSelected),
                                    .allowLan(isSelected: allowLanSelected),
                                    .circunventCensorship(isSelected: circumventCensorshipSelected)
        ])
    }

    func entrySelected(_ entry: ConnectionsEntryType, action: MenuEntryActionResponseType) {
        actionSelected(action)

        switch entry {
        case .networkOptions:
            networkOptionsSelected()
        case .connectionMode:
            if case .multiple(let currentOption, let parentId) = action {
                if parentId == ConnectionSecondaryEntryIDs.protocolMenu.id {
                    updateProtocol(value: currentOption)
                } else if parentId == ConnectionSecondaryEntryIDs.portMenu.id {
                    updatePort(value: currentOption)
                } else {
                    updateConnectionMode(value: currentOption)
                    preferences.saveConnectionMode(mode: currentOption)
                }
            }
            if case .infoLink = action {
                openLink(.connectionModes)
            }
        case .connectedDns:
            if case .multiple(let currentOption, _) = action {
                preferences.saveConnectedDNS(mode: currentOption)
            }
            if case .infoLink = action {
                openLink(.connectedDNS)
            }
            if case .field(let value, _) = action {
                saveConnectedDNSValue(value: value)
            }
        case .alwaysOn:
            if case .toggle(let isSelected, _) = action {
                preferences.saveKillSwitch(killSwitch: isSelected)
            }
        case .allowLan:
            if case .toggle(let isSelected, _) = action {
                preferences.saveAllowLane(mode: isSelected)
            }
            if case .infoLink = action {
                openLink(.allowLan)
            }
        case .circunventCensorship:
            if case .toggle(let isSelected, _) = action {
                preferences.saveCircumventCensorshipStatus(status: isSelected)
            }
            if case .infoLink = action {
                openLink(.circumventCensorship)
            }
        }
    }

    private func networkOptionsSelected() {
        router.navigate(to: .networkOptions)
    }

    private func openLink(_ linkType: FeatureExplainer) {
        safariURL = URL(string: linkType.getUrl())
    }

    private func getPorts(by protocolType: String) -> [String] {
        guard let portsArray = localDatabase.getPorts(protocolType: protocolType) else { return [] }
        return portsArray
    }

    private func getProtocols() -> [String] {
        return TextsAsset.General.protocols
    }

    private func updateConnectionMode(value: String) {
        preferences.saveConnectionMode(mode: value)
        Task {
            await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
        }
    }

    private func updateProtocol(value: String) {
        preferences.saveSelectedProtocol(selectedProtocol: value)
        if let port = localDatabase.getPorts(protocolType: value) {
            preferences.saveSelectedPort(port: port[0])
        }
        Task {
            await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
        }
    }

    private func updatePort(value: String) {
        preferences.saveSelectedPort(port: value)
        Task {
            await protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
        }
    }

    private func saveConnectedDNSValue(value: String) {
        DNSSettingsManager.getDNSValue(from: value, opensURL: UIApplication.shared, completionDNS: { dnsValue in
            guard let dnsValue = dnsValue,
                  !dnsValue.servers.isEmpty else {
                return
            }
            self.preferences.saveCustomDNSValue(value: dnsValue)
            self.reloadItems()
        }, completion: { _ in })
    }
}

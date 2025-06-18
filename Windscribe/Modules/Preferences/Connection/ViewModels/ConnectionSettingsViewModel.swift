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

protocol ConnectionSettingsViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var entries: [ConnectionsEntryType] { get set }
    var safariURL: URL? { get }
    var router: ConnectionsNavigationRouter { get }

    func entrySelected(_ entry: ConnectionsEntryType, action: MenuEntryActionResponseType)
}

class ConnectionSettingsViewModelImpl: ConnectionSettingsViewModel {
    @Published var isDarkMode: Bool = false
    @Published var entries: [ConnectionsEntryType] = []
    @Published var safariURL: URL?
    @Published var router: ConnectionsNavigationRouter

    private var cancellables = Set<AnyCancellable>()
    private var killSwitchSelected = DefaultValues.killSwitch
    private var allowLanSelected = DefaultValues.allowLANMode
    private var circumventCensorshipSelected = DefaultValues.circumventCensorship

    private var connectionMode = DefaultValues.connectionMode
    private var connectedDNS = DefaultValues.connectedDNS

    // MARK: - Dependencies
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let preferences: Preferences

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         preferences: Preferences,
         router: ConnectionsNavigationRouter) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.preferences = preferences
        self.router = router

        bindSubjects()
        reloadItems()
    }

    private func bindSubjects() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ConnectionSettingsViewModel", "darkTheme error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
                self?.reloadItems()
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

    private func reloadItems() {
        let customDNSValue = preferences.getCustomDNSValue().value
        let connectionModes = zip(TextsAsset.connectionModes,
                                        Fields.connectionModes)
            .map { MenuOption(title: $0, fieldKey: $1) }
        let connectedDNSOptions = zip(TextsAsset.connectedDNSOptions,
                                        Fields.connectedDNSOptions)
            .map { MenuOption(title: $0, fieldKey: $1) }

        entries = [
            .networkOptions,
            .connectionMode(currentOption: connectionMode,
                            options: connectionModes),
            .connectedDns(currentOption: connectedDNS,
                          customValue: customDNSValue,
                          options: connectedDNSOptions),
            .alwaysOn(isSelected: killSwitchSelected),
            .allowLan(isSelected: allowLanSelected),
            .circunventCensorship(isSelected: circumventCensorshipSelected)
        ]
    }

    func entrySelected(_ entry: ConnectionsEntryType, action: MenuEntryActionResponseType) {
        switch entry {
        case .networkOptions:
            networkOptionsSelected()
        case .connectionMode:
            if case .multiple(let currentOption, _) = action {
                preferences.saveConnectionMode(mode: currentOption)
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

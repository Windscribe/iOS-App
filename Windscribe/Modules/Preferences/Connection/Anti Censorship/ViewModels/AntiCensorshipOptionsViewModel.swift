//
//  AntiCensorshipOptionsViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/03/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol AntiCensorshipOptionsViewModel: PreferencesBaseViewModel {
    var entries: [AntiCensorshipOptionsEntryType] { get }
    var safariURL: URL? { get }

    func entrySelected(_ entry: AntiCensorshipOptionsEntryType, action: MenuEntryActionResponseType)
}

class AntiCensorshipOptionsViewModelImpl: PreferencesBaseViewModelImpl, AntiCensorshipOptionsViewModel {
    @Published var entries: [AntiCensorshipOptionsEntryType] = []
    @Published var safariURL: URL?

    private var circumventCensorshipSelected = DefaultValues.circumventCensorship
    private var selectedUnblockWgParam = ""
    private var selectedRoutingType: ServerRoutingType = .auto

    // MARK: - Dependencies
    private let antiCensorshipRepository: AntiCensorshipRepository

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         antiCensorshipRepository: AntiCensorshipRepository) {
        self.antiCensorshipRepository = antiCensorshipRepository

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)
    }

    override func bindSubjects() {
        super.bindSubjects()

        antiCensorshipRepository.useProtocolTweaksSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self = self else { return }
                self.circumventCensorshipSelected = enabled
                self.reloadItems()
            }
            .store(in: &cancellables)

        antiCensorshipRepository.selecteRoutingTypeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] routingType in
                guard let self = self else { return }
                self.selectedRoutingType = routingType
                self.reloadItems()
            }
            .store(in: &cancellables)

        antiCensorshipRepository.selectedWgParamSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] param in
                guard let self = self else { return }
                self.selectedUnblockWgParam = param?.title ?? ""
                self.reloadItems()
            }
            .store(in: &cancellables)
    }

    override func reloadItems() {
        let paramOptions = antiCensorshipRepository.unlockParams
            .map { MenuOption(title: $0.title, fieldKey: $0.id) }

        let routingOptions = ServerRoutingType.allCases.map {
            MenuOption(title: $0.title, fieldKey: $0.rawValue)
        }

        entries = [
            .info,
            .protocolTweaks(isSelected: circumventCensorshipSelected,
                            paramSelected: selectedUnblockWgParam,
                            paramOptions: paramOptions),
            .routingType(selectedRoutingType: selectedRoutingType.title,
                         routingOptions: routingOptions)
        ]
    }

    func entrySelected(_ entry: AntiCensorshipOptionsEntryType, action: MenuEntryActionResponseType) {
        actionSelected(action)

        switch entry {
        case .info:
            openLink(.circumventCensorship)
        case .protocolTweaks:
            if case .toggle(let isSelected, _) = action {
                updateCircumventCensorshipEnabled(isSelected)
            }
            if case .multiple(let currentOption, _) = action {
                updateUnblockWgParam(currentOption)
            }
            if case .infoLink = action {
                openLink(.circumventCensorship)
            }
        case .routingType:
            if case .multiple(let currentOption, _) = action {
                updateRoutingOption(currentOption)
            }
            if case .infoLink = action {
                openLink(.circumventCensorship)
            }
        }
    }

    // MARK: - Private Methods

    private func updateCircumventCensorshipEnabled(_ enabled: Bool) {
        antiCensorshipRepository.setUseProtocolTweaks(enabled)
        logger.logI("AntiCensorshipOptionsViewModel", "Circumvent censorship enabled: \(enabled)")
        reloadItems()
    }

    private func updateUnblockWgParam(_ param: String) {
        antiCensorshipRepository.setWgParameter(withId: param)
        logger.logI("AntiCensorshipOptionsViewModel", "Selected unblock WG param: \(param)")
        reloadItems()
    }

    private func updateRoutingOption(_ fieldValue: String) {
        selectedRoutingType = ServerRoutingType(rawValue: fieldValue) ?? .auto
        logger.logI("AntiCensorshipOptionsViewModel", "Selected serverpede backup: \(selectedRoutingType)")
        antiCensorshipRepository.setServerRoutingType(selectedRoutingType)
        reloadItems()
    }

    private func openLink(_ linkType: FeatureExplainer) {
        safariURL = URL(string: linkType.getUrl())
    }
}

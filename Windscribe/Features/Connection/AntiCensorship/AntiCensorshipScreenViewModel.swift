//
//  AntiCensorshipScreenViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

@available(iOS 17.0, *)
@Observable
@MainActor
final class AntiCensorshipScreenViewModel {

    // MARK: - Private State
    private var hasStarted = false
    private var circumventCensorshipSelected = DefaultValues.circumventCensorship
    private var selectedUnblockWgParam = ""
    private var selectedRoutingType: ServerRoutingType = .auto

    // MARK: - Dependencies
    private let antiCensorshipManaging: any AntiCensorshipManaging
    private let logger: any LogStoring

    // MARK: - Published State
    var safariURL: URL?
    var showingSafari: Bool = false

    // MARK: - Entries
    var entries: [AntiCensorshipOptionsEntryType] {
        let paramOptions = antiCensorshipManaging.unlockParams
            .map { MenuOption(title: $0.title, fieldKey: $0.id) }

        let routingOptions = ServerRoutingType.allCases.map {
            MenuOption(title: $0.title, fieldKey: $0.rawValue)
        }

        return [
            .info,
            .protocolTweaks(
                isSelected: circumventCensorshipSelected,
                paramSelected: selectedUnblockWgParam,
                paramOptions: paramOptions
            ),
            .routingType(
                selectedRoutingType: selectedRoutingType.title,
                routingOptions: routingOptions
            )
        ]
    }

    // MARK: - Initialization
    init(antiCensorshipManaging: any AntiCensorshipManaging,
        logger: any LogStoring) {
        self.antiCensorshipManaging = antiCensorshipManaging
        self.logger = logger

        // Initialize current state
        self.circumventCensorshipSelected = antiCensorshipManaging.useProtocolTweaks
        self.selectedUnblockWgParam = antiCensorshipManaging.selectedWgParam?.title ?? ""
        self.selectedRoutingType = antiCensorshipManaging.serverRoutingType
    }

    // MARK: - Lifecycle
    func startObservers() async {
        guard !hasStarted else { return }
        hasStarted = true

        async let tweaks: () = observeProtocolTweaks()
        async let routing: () = observeServerRoutingType()
        async let param: () = observeWgParam()

        _ = await (tweaks, routing, param)
    }

    private func observeProtocolTweaks() async {
        for await value in antiCensorshipManaging.useProtocolTweaksUpdates {
            circumventCensorshipSelected = value
        }
    }

    private func observeServerRoutingType() async {
        for await value in antiCensorshipManaging.serverRoutingTypeUpdates {
            selectedRoutingType = value
        }
    }

    private func observeWgParam() async {
        for await value in antiCensorshipManaging.selectedWgParamUpdates {
            selectedUnblockWgParam = value?.title ?? ""
        }
    }

    // MARK: - Actions (called by the view)
    func entrySelected(_ entry: AntiCensorshipOptionsEntryType, action: MenuEntryActionResponseType) {
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
        antiCensorshipManaging.setUseProtocolTweaks(enabled)
        logger.logI("AntiCensorshipScreenViewModel", "Circumvent censorship enabled: \(enabled)")
    }

    private func updateUnblockWgParam(_ param: String) {
        antiCensorshipManaging.setWgParameter(withId: param)
        logger.logI("AntiCensorshipScreenViewModel", "Selected unblock WG param: \(param)")
    }

    private func updateRoutingOption(_ fieldValue: String) {
        let routingType = ServerRoutingType(rawValue: fieldValue) ?? .auto
        logger.logI("AntiCensorshipScreenViewModel", "Selected serverpede backup: \(routingType)")
        antiCensorshipManaging.setServerRoutingType(routingType)
    }

    private func openLink(_ linkType: FeatureExplainer) {
        if let url = URL(string: linkType.getUrl()) {
            safariURL = url
            showingSafari = true
        }
    }
}

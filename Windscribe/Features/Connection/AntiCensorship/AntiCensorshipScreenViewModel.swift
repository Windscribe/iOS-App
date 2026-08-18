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
    private var isObserving = false
    private var selectedProtocolTweaksMode: ProtocolTweaksMode = .auto
    private var selectedUnblockWgParam = ""
    private var selectedRoutingType: ServerRoutingType = .auto
    private var tlsServerName = ""

    // MARK: - Dependencies
    private let antiCensorshipManaging: any AntiCensorshipManaging
    private let hapticFeedback: any HapticFeedbacking
    private let logger: any LogStoring
    private let preferencesWriting: any PreferencesWriting

    // MARK: - Published State
    var safariURL: URL?
    var showingSafari: Bool = false

    // MARK: - Entries
    var entries: [AntiCensorshipOptionsEntryType] {
        let modeOptions = ProtocolTweaksMode.allCases.map {
            MenuOption(title: $0.title, fieldKey: $0.rawValue)
        }

        let paramOptions = antiCensorshipManaging.unlockParams
            .map { MenuOption(title: $0.title, fieldKey: $0.id) }

        let routingOptions = ServerRoutingType.allCases.map {
            MenuOption(title: $0.title, fieldKey: $0.rawValue)
        }

        return [
            .info,
            .protocolTweaks(
                selectedMode: selectedProtocolTweaksMode,
                modeOptions: modeOptions,
                paramSelected: selectedUnblockWgParam,
                paramOptions: paramOptions
            ),
            .routingType(
                selectedRoutingType: selectedRoutingType.title,
                routingOptions: routingOptions
            ),
            .tlsServerName(
                value: tlsServerName,
                placeholder: TextsAsset.Connection.tlsServerNameValueFieldDescription
            )
        ]
    }

    // MARK: - Initialization
    init(antiCensorshipManaging: any AntiCensorshipManaging,
         hapticFeedback: any HapticFeedbacking,
         logger: any LogStoring,
         preferencesReading: any PreferencesReading,
         preferencesWriting: any PreferencesWriting) {
        self.antiCensorshipManaging = antiCensorshipManaging
        self.hapticFeedback = hapticFeedback
        self.logger = logger
        self.preferencesWriting = preferencesWriting

        selectedProtocolTweaksMode = antiCensorshipManaging.protocolTweaksMode
        selectedUnblockWgParam = antiCensorshipManaging.selectedWgParam?.title ?? ""
        selectedRoutingType = antiCensorshipManaging.serverRoutingType
        tlsServerName = preferencesReading.tlsServerName ?? ""
    }

    // MARK: - Lifecycle
    func startObservers() async {
        guard !isObserving else { return }
        isObserving = true
        defer { isObserving = false }

        async let tweaks: () = observeProtocolTweaksMode()
        async let routing: () = observeServerRoutingType()
        async let param: () = observeWgParam()

        _ = await (tweaks, routing, param)
    }

    private func observeProtocolTweaksMode() async {
        for await value in antiCensorshipManaging.protocolTweaksModeUpdates {
            selectedProtocolTweaksMode = value
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
        hapticFeedback.checkSettingsAction(action: action)

        switch entry {
        case .info:
            openLink(.circumventCensorship)

        case .protocolTweaks:
            if case .multiple(let currentOption, let parentId) = action {
                if parentId == entry.id {
                    updateProtocolTweaksMode(currentOption)
                } else if parentId == AntiCensorshipOptionsSecondaryIDs.wgUnlockMenu.id {
                    updateUnblockWgParam(currentOption)
                }
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

        case .tlsServerName:
            if case .field(let value, _) = action {
                tlsServerName = value
                preferencesWriting.saveTlsServerName(value: value)
            }
        }
    }

    // MARK: - Private Methods
    private func updateProtocolTweaksMode(_ fieldValue: String) {
        let mode = ProtocolTweaksMode(rawValue: fieldValue) ?? .auto
        selectedProtocolTweaksMode = mode
        antiCensorshipManaging.setProtocolTweaksMode(mode)
        selectedUnblockWgParam = antiCensorshipManaging.selectedWgParam?.title ?? ""
        logger.logI("AntiCensorshipScreenViewModel", "Protocol tweaks mode: \(mode.rawValue)")
    }

    private func updateUnblockWgParam(_ param: String) {
        antiCensorshipManaging.setWgParameter(withId: param)
        selectedUnblockWgParam = antiCensorshipManaging.selectedWgParam?.title ?? ""
        logger.logI("AntiCensorshipScreenViewModel", "Selected unblock WG param: \(param)")
    }

    private func updateRoutingOption(_ fieldValue: String) {
        let routingType = ServerRoutingType(rawValue: fieldValue) ?? .auto
        selectedRoutingType = routingType
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

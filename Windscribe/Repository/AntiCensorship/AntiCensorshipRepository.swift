//
//  AntiCensorshipRepository.swift
//  Windscribe
//
//  Created by Windscribe on 2026-03-24.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol AntiCensorshipRepository: Sendable {
    var protocolTweaksModeSubject: CurrentValueSubject<ProtocolTweaksMode, Never> { get }
    var useProtocolTweaksSubject: CurrentValueSubject<Bool, Never> { get }
    var selecteRoutingTypeSubject: CurrentValueSubject<ServerRoutingType, Never> { get }
    var selectedWgParamSubject: CurrentValueSubject<UnblockWgParams?, Never> { get }

    var unlockParams: [UnblockWgParams] { get }

    func setServerRoutingType(_ value: ServerRoutingType)
    func setProtocolTweaksMode(_ value: ProtocolTweaksMode)

    func setWgParameter(withId id: String)
    func setSessionWgParameter(withId id: String)

    func needsRefresh() -> Bool
    func tryRefresh()
    func refreshParams()
}

class AntiCensorshipRepositoryImpl: AntiCensorshipRepository {

    var unlockParams: [UnblockWgParams] = []

    var protocolTweaksModeSubject = CurrentValueSubject<ProtocolTweaksMode, Never>(.auto)
    var selectedWgParamSubject = CurrentValueSubject<UnblockWgParams?, Never>(nil)
    var useProtocolTweaksSubject = CurrentValueSubject<Bool, Never>(false)
    var selecteRoutingTypeSubject = CurrentValueSubject<ServerRoutingType, Never>(.auto)

    private let apiManager: APIManager
    private let logger: FileLogger
    private let localDatabase: LocalDatabase
    private let preferences: Preferences

    private var sessionHasBackup: Bool = false
    private var sessionWgParameterKey: String?
    private var isRefreshing = false

    init(apiManager: APIManager,
         logger: FileLogger,
         localDatabase: LocalDatabase,
         preferences: Preferences) {
        self.apiManager = apiManager
        self.logger = logger
        self.localDatabase = localDatabase
        self.preferences = preferences

        unlockParams = localDatabase.getUnblockWgParams()
        protocolTweaksModeSubject.send(loadProtocolTweaksMode())
        selecteRoutingTypeSubject.send(preferences.getRoutingType())
        applyProtocolTweaksMode()
    }

    // MARK: - Setting values
    func setProtocolTweaksMode(_ value: ProtocolTweaksMode) {
        preferences.saveProtocolTweaksMode(value.rawValue)
        preferences.saveAntiCensorshipManuallyConfigured(status: value != .auto)
        protocolTweaksModeSubject.send(value)
        applyProtocolTweaksMode()
    }

    private func loadProtocolTweaksMode() -> ProtocolTweaksMode {
        if let value = preferences.getProtocolTweaksMode(),
           let mode = ProtocolTweaksMode(rawValue: value) {
            return mode
        }

        let mode: ProtocolTweaksMode
        if preferences.isAntiCensorshipManuallyConfigured() {
            mode = preferences.isCircumventCensorshipEnabled() ? .enabled : .disabled
        } else {
            mode = .auto
        }
        preferences.saveProtocolTweaksMode(mode.rawValue)
        return mode
    }

    private func applyProtocolTweaksMode() {
        switch protocolTweaksModeSubject.value {
        case .auto:
            applySessionRecommendation()
        case .enabled:
            applyEffectiveProtocolTweaks(true)
            restoreSelectedWgParam()
        case .disabled:
            applyEffectiveProtocolTweaks(false)
        }
    }

    private func applySessionRecommendation() {
        guard let id = sessionWgParameterKey,
              let param = unlockParams.first(where: { $0.id == id }) else {
            applyEffectiveProtocolTweaks(false)
            return
        }

        applyEffectiveProtocolTweaks(true)
        selectParam(with: param)
    }

    private func applyEffectiveProtocolTweaks(_ value: Bool) {
        preferences.saveCircumventCensorshipStatus(status: value)
        useProtocolTweaksSubject.send(value)

        if !value {
            selectedWgParamSubject.send(nil)
        }
    }

    private func restoreSelectedWgParam() {
        if let saved = preferences.getUnblockWgParams(),
           let param = unlockParams.first(where: { $0.id == saved.id }) {
            selectParam(with: param)
        } else if let first = unlockParams.first {
            selectParam(with: first)
        }
    }

    func setServerRoutingType(_ value: ServerRoutingType) {
        preferences.saveRoutingType(routingType: value)
        selecteRoutingTypeSubject.send(value)
    }

    func setSessionWgParameter(withId id: String) {
        sessionWgParameterKey = id.isEmpty ? nil : id

        if protocolTweaksModeSubject.value == .auto {
            applySessionRecommendation()
        }
    }

    func setWgParameter(withId id: String) {
        guard protocolTweaksModeSubject.value == .enabled else { return }
        preferences.saveAntiCensorshipManuallyConfigured(status: true)
        if let param = unlockParams.first(where: { $0.id == id }) {
            selectParam(with: param)
        }
    }

    private func selectParam(with param: UnblockWgParams) {
        guard useProtocolTweaksSubject.value else { return }
        selectedWgParamSubject.send(param)
        preferences.saveUnblockWgParams(param: param)
    }

    // MARK: - Refresh of Params
    func needsRefresh() -> Bool {
        guard !isRefreshing else { return false }
        let isEmpty = unlockParams.compactMap { $0.title.isEmpty ? nil : $0.title }.isEmpty
        let needsEnabledSelection = protocolTweaksModeSubject.value == .enabled && selectedWgParamSubject.value == nil
        let needsAutomaticSelection = protocolTweaksModeSubject.value == .auto &&
            sessionWgParameterKey != nil && selectedWgParamSubject.value == nil
        return isEmpty || needsEnabledSelection || needsAutomaticSelection
    }

    func tryRefresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        self.refreshParams()
    }

    func refreshParams() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                isRefreshing = true
                logger.logI("UnblockWgParamsRepository", "Refreshing wg unblock params")
                unlockParams = try await apiManager.wgUnlockParams().params
                localDatabase.saveUnblockWgParams(params: unlockParams)
                applyProtocolTweaksMode()
            } catch {
                logger.logE("UnblockWgParamsRepository", "Failed Refreshing wg unblock params with error: \(error)")
                isRefreshing = false
                return
            }
            // Will only allow for new refresh after one minute in case the user
            // switches between background and foreground multiple times.
            try? await Task.sleep(nanoseconds: 60_000_000_000)
            isRefreshing = false
        }
    }
}

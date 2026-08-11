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
    var useProtocolTweaksSubject: CurrentValueSubject<Bool, Never> { get }
    var selecteRoutingTypeSubject: CurrentValueSubject<ServerRoutingType, Never> { get }
    var selectedWgParamSubject: CurrentValueSubject<UnblockWgParams?, Never> { get }

    var unlockParams: [UnblockWgParams] { get }

    func setServerRoutingType(_ value: ServerRoutingType)

    func setUseProtocolTweaks(_ value: Bool)

    func setWgParameter(withId id: String)
    func setSessionWgParameter(withId id: String)

    func needsRefresh() -> Bool
    func tryRefresh()
    func refreshParams()
}

class AntiCensorshipRepositoryImpl: AntiCensorshipRepository {

    var unlockParams: [UnblockWgParams] = []

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

        selectedWgParamSubject.send(preferences.getUnblockWgParams())
        useProtocolTweaksSubject.send(preferences.isCircumventCensorshipEnabled())
        selecteRoutingTypeSubject.send(preferences.getRoutingType())
    }

    // MARK: - Setting values
    func setUseProtocolTweaks(_ value: Bool) {
        preferences.saveAntiCensorshipManuallyConfigured(status: true)
        applyUseProtocolTweaks(value)
    }

    private func applyUseProtocolTweaks(_ value: Bool) {
        preferences.saveCircumventCensorshipStatus(status: value)
        useProtocolTweaksSubject.send(value)

        if value {
            updateSelectedWgParam()
        } else {
            selectedWgParamSubject.send(nil)
        }
    }

    private func updateSelectedWgParam() {
        if selectedWgParamSubject.value == nil {
            if let sessionWgParameterKey = sessionWgParameterKey {
                applyWgParameter(withId: sessionWgParameterKey)
            } else if let first = unlockParams.first {
                selectParam(with: first)
            }
        }
    }

    func setServerRoutingType(_ value: ServerRoutingType) {
        preferences.saveRoutingType(routingType: value)
        selecteRoutingTypeSubject.send(value)
    }

    func setSessionWgParameter(withId id: String) {
        if id.isEmpty {
            sessionWgParameterKey = nil
        } else {
            sessionWgParameterKey = id

            guard !preferences.isAntiCensorshipManuallyConfigured() else { return }

            if useProtocolTweaksSubject.value == false {
                applyUseProtocolTweaks(true)
            }
            applyWgParameter(withId: id)
        }
    }

    func setWgParameter(withId id: String) {
        preferences.saveAntiCensorshipManuallyConfigured(status: true)
        applyWgParameter(withId: id)
    }

    private func applyWgParameter(withId id: String) {
        guard useProtocolTweaksSubject.value else { return }
        if let first = unlockParams.first(where: { $0.id == id }) {
            selectParam(with: first)
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
        return selectedWgParamSubject.value == nil || isEmpty
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

                updateSelectedWgParam()
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

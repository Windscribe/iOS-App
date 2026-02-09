//
//  UnblockWgParamsRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 02/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Combine

protocol UnblockWgParamsRepository {
    var unlockParams: [UnblockWgParams] { get }
    var selectedParamTitleSubject: CurrentValueSubject<String?, Never> { get }
    func needsRefresh() -> Bool
    func tryRefresh()
    func refreshParams()
    func selectParamTitle(with paramTitle: String)
}

class UnblockWgParamsRepositoryImpl: UnblockWgParamsRepository {
    var unlockParams: [UnblockWgParams] = []
    var selectedParamTitleSubject = CurrentValueSubject<String?, Never>(nil)

    private let apiManager: APIManager
    private let logger: FileLogger
    private let localDatabase: LocalDatabase
    private let preferences: Preferences

    private var cancellables = Set<AnyCancellable>()
    private var isRefreshing = false

    init(apiManager: APIManager,
         logger: FileLogger,
         localDatabase: LocalDatabase,
         preferences: Preferences) {
        self.apiManager = apiManager
        self.logger = logger
        self.localDatabase = localDatabase
        self.preferences = preferences

        unlockParams = localDatabase.getUnblockWgParams().compactMap {
            if $0.isInvalidated { return nil }
            return $0.getModel()
        }

        selectedParamTitleSubject.send(preferences.getUnblockWgParams()?.title)
        if selectedParamTitleSubject.value == nil, !unlockParams.isEmpty {
            selectParam(with: unlockParams[0])
        }
    }

    func needsRefresh() -> Bool {
        guard !isRefreshing else { return false }
        return selectedParamTitleSubject.value == nil || unlockParams.isEmpty
    }

    func tryRefresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        self.refreshParams()
    }

    func refreshParams() {
        Task {
            do {
                isRefreshing = true
                logger.logI("UnblockWgParamsRepository", "Refreshing wg unblock params")
                unlockParams = try await apiManager.wgUnlockParams().params
                localDatabase.saveUnblockWgParams(params: unlockParams.map {$0.getObject()})

                if selectedParamTitleSubject.value == nil, !unlockParams.isEmpty {
                    selectParam(with: unlockParams[0])
                }

            } catch {
                logger.logI("UnblockWgParamsRepository", "Failed Refreshing wg unblock params with error: \(error)")
            }
            // Will only allow for new refresh after one minute in case the user
            // switches between background and foreground multiple times
            Just(())
                .delay(for: .seconds(60), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.isRefreshing = false
                }
                .store(in: &cancellables)
        }
    }

    func selectParamTitle(with paramTitle: String) {
        if let first = unlockParams.first(where: { $0.title == paramTitle }) {
            selectParam(with: first)
        }
    }

    private func selectParam(with param: UnblockWgParams) {
        selectedParamTitleSubject.send(param.title)
        preferences.saveUnblockWgParams(param: param)
    }
}

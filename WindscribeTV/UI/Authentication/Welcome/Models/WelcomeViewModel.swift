//
//  WelcomeViewModal.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-02-29.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol WelcomeViewModel {
    var showLoadingView: CurrentValueSubject<Bool, Never> { get }
    var routeToMainView: PassthroughSubject<Bool, Never> { get }
    var routeToSignup: PassthroughSubject<Bool, Never> { get }
    var emergencyConnectStatus: CurrentValueSubject<Bool, Never> { get }
    var failedState: CurrentValueSubject<String?, Never> { get }
    func continueButtonTapped()
}

class WelcomeViewModelImpl: WelcomeViewModel {
    let showLoadingView = CurrentValueSubject<Bool, Never>(false)
    let routeToSignup = PassthroughSubject<Bool, Never>()
    let routeToMainView = PassthroughSubject<Bool, Never>()
    let failedState = CurrentValueSubject<String?, Never>(nil)
    let emergencyConnectStatus = CurrentValueSubject<Bool, Never>(false)

    let userSessionRepository: UserSessionRepository
    let sessionManager: SessionManager
    let keyChainDatabase: KeyChainDatabase
    let userDataRepository: UserDataRepository
    let apiManager: APIManager
    let preferences: Preferences
    let vpnStateRepository: VPNStateRepository
    let logger: FileLogger
    private var cancellables = Set<AnyCancellable>()

    init(userSessionRepository: UserSessionRepository,
         sessionManager: SessionManager,
         keyChainDatabase: KeyChainDatabase,
         userDataRepository: UserDataRepository,
         apiManager: APIManager,
         preferences: Preferences,
         vpnStateRepository: VPNStateRepository,
         logger: FileLogger) {
        self.userSessionRepository = userSessionRepository
        self.sessionManager = sessionManager
        self.keyChainDatabase = keyChainDatabase
        self.userDataRepository = userDataRepository
        self.apiManager = apiManager
        self.preferences = preferences
        self.vpnStateRepository = vpnStateRepository
        self.logger = logger
        listenForVPNStateChange()
    }

    func continueButtonTapped() {
        if keyChainDatabase.isGhostAccountCreated() {
            logger.logD("WelcomeViewModelImpl", "Ghost account already created from this device.")
            routeToSignup.send(true)
            return
        }
        showLoadingView.send(true)

        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                let result = try await self.apiManager.regToken()
                let sessionModel = try await self.apiManager.signUpUsingToken(token: result.token)

                Task { @MainActor in
                    await self.sessionManager.updateFrom(session: sessionModel)
                    self.keyChainDatabase.setGhostAccountCreated()
                    self.logger.logE("WelcomeViewModelImpl", "Ghost account registration successful, Preparing user data for \(sessionModel.userId)")
                    self.prepareUserData()
                }
            } catch {
                await MainActor.run {
                    switch error {
                    case Errors.apiError(let e):
                        self.logger.logE("WelcomeViewModelImpl", "Failed to get ghost registration token: \(String(describing: e.errorMessage))")
                    default: ()
                    }
                    self.showLoadingView.send(false)
                    self.routeToSignup.send(true)
                }
            }
        }
    }

    private func prepareUserData() {
        Task {
            do {
                try await userDataRepository.prepareUserData()

                logger.logD("WelcomeViewModelImpl", "User data is ready")
                showLoadingView.send(false)
                routeToMainView.send(true)
            } catch {
                preferences.clearSessionAuth()
                userSessionRepository.clearSession()
                logger.logE("WelcomeViewModelImpl", "Failed to prepare user data: \(error)")
                showLoadingView.send(false)
                switch error {
                case Errors.apiError(let e):
                    failedState.send(e.errorMessage ?? "")
                default:
                    if let error = error as? Errors {
                        failedState.send(error.description)
                    } else {
                        failedState.send(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func listenForVPNStateChange() {
        vpnStateRepository.vpnInfo.sink { [weak self] vpnInfo in
            if vpnInfo != nil && vpnInfo?.status == .connected {
                self?.emergencyConnectStatus.send(true)
            } else {
                self?.emergencyConnectStatus.send(false)
            }
        }.store(in: &cancellables)
    }
}

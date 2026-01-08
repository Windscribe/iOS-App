//
//  WelcomeViewModal.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-02-29.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine

protocol WelcomeViewModel {
    var showLoadingView: BehaviorSubject<Bool> { get }
    var routeToMainView: PublishSubject<Bool> { get }
    var routeToSignup: PublishSubject<Bool> { get }
    var emergencyConnectStatus: BehaviorSubject<Bool> { get }
    var failedState: BehaviorSubject<String?> { get }
    func continueButtonTapped()
}

class WelcomeViewModelImpl: WelcomeViewModel {
    let showLoadingView = BehaviorSubject(value: false)
    let routeToSignup = PublishSubject<Bool>()
    let routeToMainView = PublishSubject<Bool>()
    let failedState = BehaviorSubject<String?>(value: nil)
    let emergencyConnectStatus =  BehaviorSubject<Bool>(value: false)

    let userSessionRepository: UserSessionRepository
    let sessionManager: SessionManager
    let keyChainDatabase: KeyChainDatabase
    let userDataRepository: UserDataRepository
    let apiManager: APIManager
    let preferences: Preferences
    let vpnStateRepository: VPNStateRepository
    let logger: FileLogger
    let disposeBag = DisposeBag()
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
            routeToSignup.onNext(true)
            return
        }
        showLoadingView.onNext(true)

        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                let result = try await self.apiManager.regToken()
                let session = try await self.apiManager.signUpUsingToken(token: result.token)

                self.sessionManager.updateFrom(session: session)
                await MainActor.run {
                    self.keyChainDatabase.setGhostAccountCreated()
                    self.logger.logE("WelcomeViewModelImpl", "Ghost account registration successful, Preparing user data for \(session.userId)")
                    self.prepareUserData()
                }
            } catch {
                await MainActor.run {
                    switch error {
                    case Errors.apiError(let e):
                        self.logger.logE("WelcomeViewModelImpl", "Failed to get ghost registration token: \(String(describing: e.errorMessage))")
                    default: ()
                    }
                    self.showLoadingView.onNext(false)
                    self.routeToSignup.onNext(true)
                }
            }
        }
    }

    private func prepareUserData() {
        Task {
            do {
                try await userDataRepository.prepareUserData()

                logger.logD("WelcomeViewModelImpl", "User data is ready")
                showLoadingView.onNext(false)
                routeToMainView.onNext(true)
            } catch {
                preferences.saveUserSessionAuth(sessionAuth: nil)
                userSessionRepository.clearSession()
                logger.logE("WelcomeViewModelImpl", "Failed to prepare user data: \(error)")
                showLoadingView.onNext(false)
                switch error {
                case Errors.apiError(let e):
                    failedState.onNext(e.errorMessage ?? "")
                default:
                    if let error = error as? Errors {
                        failedState.onNext(error.description)
                    } else {
                        failedState.onNext(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func listenForVPNStateChange() {
        vpnStateRepository.vpnInfo.sink { [weak self] vpnInfo in
            if vpnInfo != nil && vpnInfo?.status == .connected {
                self?.emergencyConnectStatus.onNext(true)
            } else {
                self?.emergencyConnectStatus.onNext(false)
            }
        }.store(in: &cancellables)
    }
}

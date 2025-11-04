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
    let keyChainDatabase: KeyChainDatabase
    let userDataRepository: UserDataRepository
    let apiManager: APIManager
    let preferences: Preferences
    let vpnStateRepository: VPNStateRepository
    let logger: FileLogger
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    init(userSessionRepository: UserSessionRepository,
         keyChainDatabase: KeyChainDatabase,
         userDataRepository: UserDataRepository,
         apiManager: APIManager,
         preferences: Preferences,
         vpnStateRepository: VPNStateRepository,
         logger: FileLogger) {
        self.userSessionRepository = userSessionRepository
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

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let result = try await self.apiManager.regToken()
                let session = try await self.apiManager.signUpUsingToken(token: result.token)

                await MainActor.run {
                    self.keyChainDatabase.setGhostAccountCreated()
                    self.userSessionRepository.login(session: session)
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
        userDataRepository.prepareUserData().observe(on: MainScheduler.instance).subscribe(onSuccess: { [weak self] _ in
            self?.logger.logD("WelcomeViewModelImpl", "User data is ready")
            self?.showLoadingView.onNext(false)
            self?.routeToMainView.onNext(true)
        }, onFailure: { [weak self] error in
            self?.preferences.saveUserSessionAuth(sessionAuth: nil)
            self?.logger.logE("WelcomeViewModelImpl", "Failed to prepare user data: \(error)")
            self?.showLoadingView.onNext(false)
            switch error {
            case Errors.apiError(let e):
                self?.failedState.onNext(e.errorMessage ?? "")
            default:
                if let error = error as? Errors {
                    self?.failedState.onNext(error.description)
                } else {
                    self?.failedState.onNext(error.localizedDescription)
                }
            }
        }).disposed(by: disposeBag)
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

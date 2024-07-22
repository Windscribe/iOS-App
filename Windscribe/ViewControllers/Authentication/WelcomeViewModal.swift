//
//  WelcomeViewModal.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-02-29.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
protocol WelcomeViewModal {
    var showLoadingView: BehaviorSubject<Bool> { get }
    var routeToMainView: PublishSubject<Bool> { get }
    var routeToSignup: PublishSubject<Bool> { get }
    var emergencyConnectStatus: BehaviorSubject<Bool> { get }
    var failedState: BehaviorSubject<String?> { get }
    func continueButtonTapped()
}
class WelcomeViewModelImpl: WelcomeViewModal {
    let showLoadingView = BehaviorSubject(value: false)
    let routeToSignup = PublishSubject<Bool>()
    let routeToMainView = PublishSubject<Bool>()
    let failedState = BehaviorSubject<String?>(value: nil)
    let emergencyConnectStatus =  BehaviorSubject<Bool>(value: false)

    let userRepository: UserRepository
    let keyChainDatabase: KeyChainDatabase
    let userDataRepository: UserDataRepository
    let apiManager: APIManager
    let preferences: Preferences
    let vpnManager: VPNManager
    let logger: FileLogger
    let disposeBag = DisposeBag()

    init(userRepository: UserRepository, keyChainDatabase: KeyChainDatabase, userDataRepository: UserDataRepository, apiManager: APIManager, preferences: Preferences,vpnManager: VPNManager, logger: FileLogger) {
        self.userRepository = userRepository
        self.keyChainDatabase = keyChainDatabase
        self.userDataRepository = userDataRepository
        self.apiManager = apiManager
        self.preferences = preferences
        self.vpnManager = vpnManager
        self.logger = logger
        listenForVPNStateChange()
    }

    func continueButtonTapped() {
        if keyChainDatabase.isGhostAccountCreated() {
            logger.logD(self, "Ghost account already created from this device.")
            routeToSignup.onNext(true)
            return
        }
        showLoadingView.onNext(true)
        apiManager.regToken().observe(on: MainScheduler.instance)
            .flatMap { result in
                return self.apiManager.signUpUsingToken(token: result.token)
            }.subscribe(onSuccess: { [weak self] session in
                self?.keyChainDatabase.setGhostAccountCreated()
                self?.userRepository.login(session: session)
                self?.logger.logE(WelcomeViewModelImpl.self, "Ghost account registration successful, Preparing user data for \(session.userId)")
                self?.prepareUserData()
            },onFailure: { [weak self] error in
                switch error {
                case Errors.apiError(let e):
                        self?.logger.logE(WelcomeViewModelImpl.self, "Failed to get ghost registration token: \(String(describing: e.errorMessage))")
                default: ()
                }
                self?.showLoadingView.onNext(false)
                self?.routeToSignup.onNext(true)
            }).disposed(by: disposeBag)
    }

    private func prepareUserData() {
        userDataRepository.prepareUserData().observe(on: MainScheduler.instance).subscribe(onSuccess: { [weak self] _ in
            self?.logger.logD(WelcomeViewModelImpl.self, "User data is ready")
            self?.showLoadingView.onNext(false)
            self?.routeToMainView.onNext(true)
        }, onFailure: { [weak self] error in
            self?.preferences.saveUserSessionAuth(sessionAuth: nil)
            self?.logger.logE(WelcomeViewModelImpl.self, "Failed to prepare user data: \(error)")
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
        vpnManager.vpnInfo.subscribe(onNext: { [weak self] vpnInfo in
            if vpnInfo != nil && vpnInfo?.status == .connected {
                self?.emergencyConnectStatus.onNext(true)
            } else {
                self?.emergencyConnectStatus.onNext(false)
            }
        }).disposed(by: disposeBag)
    }
}

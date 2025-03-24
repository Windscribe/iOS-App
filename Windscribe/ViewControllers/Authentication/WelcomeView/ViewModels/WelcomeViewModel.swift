//
//  WelcomeViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UIKit

protocol WelcomeViewModelProtocol: ObservableObject {
    var scrollOrder: Int { get set }
    var showLoadingView: Bool { get }
    var routeToMainView: PassthroughSubject<Bool, Never> { get }
    var routeToSignup: PassthroughSubject<Bool, Never> { get }
    var routeToLogin: PassthroughSubject<Void, Never> { get }
    var routeToEmergency: PassthroughSubject<Void, Never> { get}
    var emergencyConnectStatus: Bool { get }
    var failedState: String? { get }

    func continueButtonTapped()
}

class WelcomeViewModel: WelcomeViewModelProtocol {
    @Published var scrollOrder = 0
    @Published var showLoadingView = false
    @Published var emergencyConnectStatus = false
    @Published var failedState: String?

    let routeToSignup = PassthroughSubject<Bool, Never>()
    let routeToMainView = PassthroughSubject<Bool, Never>()
    let routeToLogin = PassthroughSubject<Void, Never>()
    let routeToEmergency = PassthroughSubject<Void, Never>()

    // Image Assets
    let backgroundImage = ImagesAsset.Welcome.background
    let iconImage = ImagesAsset.Welcome.icon
    let tabInfoImages = [
        ImagesAsset.Welcome.tabInfo1,
        ImagesAsset.Welcome.tabInfo2,
        ImagesAsset.Welcome.tabInfo3,
        ImagesAsset.Welcome.tabInfo4
    ]
    let signupGoogleImage = ImagesAsset.Welcome.googleIcon
    let signupAppleImage = ImagesAsset.Welcome.appleIcon

    // Text Assets
    let tabInfoTexts = [
        TextsAsset.Welcome.tabInfo1.localize(),
        TextsAsset.Welcome.tabInfo2,
        TextsAsset.Welcome.tabInfo3,
        TextsAsset.Welcome.tabInfo4
    ]
    let signupText = TextsAsset.Welcome.signup
    let loginText = TextsAsset.Welcome.login
    let connectionFaultText = TextsAsset.Welcome.connectionFault
    let emergencyConnectOnText = TextsAsset.Welcome.emergencyConnectOn

    private var cancellables = Set<AnyCancellable>()
    private let userRepository: UserRepository
    private let keyChainDatabase: KeyChainDatabase
    private let userDataRepository: UserDataRepository
    private let apiManager: APIManager
    private let preferences: Preferences
    private let router: WelcomeRouter
    private let vpnManager: VPNManager
    private let logger: FileLogger

    private var presentingController: UIViewController?

    init(userRepository: UserRepository,
         keyChainDatabase: KeyChainDatabase,
         userDataRepository: UserDataRepository,
         apiManager: APIManager,
         preferences: Preferences,
         router: WelcomeRouter,
         vpnManager: VPNManager,
         logger: FileLogger) {
        self.userRepository = userRepository
        self.keyChainDatabase = keyChainDatabase
        self.userDataRepository = userDataRepository
        self.apiManager = apiManager
        self.preferences = preferences
        self.router = router
        self.vpnManager = vpnManager
        self.logger = logger

        listenForVPNStateChange()
    }

    func continueButtonTapped() {
        if keyChainDatabase.isGhostAccountCreated() {
            logger.logD(self, "Ghost account already created from this device.")
            routeToSignup.send(true)
            return
        }

        showLoadingView = true

        apiManager.regToken()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] token -> AnyPublisher<Session, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "APIManagerError", code: -1, userInfo: nil) as Error)
                        .eraseToAnyPublisher()
                }

                return self.apiManager.signUpUsingToken(token: token.token).asPublisher()
            }
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case .failure(let error) = completion {
                    self.handleError(error)
                }

                self.showLoadingView = false
                self.routeToSignup.send(true)
            }, receiveValue: { [weak self] session in
                guard let self = self else { return }

                self.keyChainDatabase.setGhostAccountCreated()
                self.userRepository.login(session: session)
                self.logger.logI(WelcomeViewModel.self, "Ghost account registration successful")
                self.prepareUserData()
            })
            .store(in: &cancellables)
    }

    func continueWithGoogleTapped() {
        // TODO: Change with Google Authentication
        continueButtonTapped()
    }

    func continueWithAppleTapped() {
        // TODO: Change with Apple Authentication
        continueButtonTapped()
    }

    private func prepareUserData() {
        userDataRepository.prepareUserData()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.showLoadingView = false
                if case .failure(let error) = completion {
                    self.handleError(error)
                }
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.logger.logD(WelcomeViewModel.self, "User data is ready")
                self.routeToMainView.send(true)
            })
            .store(in: &cancellables)
    }

    private func handleError(_ error: Error) {
        self.logger.logE(WelcomeViewModel.self, "Error: \(error.localizedDescription)")
    }

    private func listenForVPNStateChange() {
        vpnManager.vpnInfo
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] vpnInfo in
                guard let self = self else { return }
                self.emergencyConnectStatus = vpnInfo?.status == .connected
            }
            .store(in: &cancellables)
    }

    func slideScrollView() {
        scrollOrder = (scrollOrder + 1) % 4
    }
}

// MARK: Navigation type action

extension WelcomeViewModel {

    func setPresentingController(_ controller: UIViewController) {
        self.presentingController = controller
    }

    func navigateToSignUp() {
        guard let presentingController = presentingController else { return }

        router.routeTo(to: RouteID.signup(claimGhostAccount: false), from: presentingController)
    }

    func navigateToLogin() {
        guard let presentingController = presentingController else { return }

        router.routeTo(to: RouteID.login, from: presentingController)
    }

    func navigateToMain() {
        guard let presentingController = presentingController else { return }

        router.routeTo(to: RouteID.home, from: presentingController)
    }

    func navigateToEmergency() {
        guard let presentingController = presentingController else { return }

        router.routeTo(to: RouteID.emergency, from: presentingController)
    }
}

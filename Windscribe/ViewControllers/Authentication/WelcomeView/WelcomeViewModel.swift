//
//  WelcomeViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol WelcomeViewModelProtocol: ObservableObject {
    var scrollOrder: Int { get set }  // ✅ Add back scrollOrder
    var showLoadingView: Bool { get }
    var routeToMainView: PassthroughSubject<Bool, Never> { get }
    var routeToSignup: PassthroughSubject<Bool, Never> { get }
    var emergencyConnectStatus: Bool { get }
    var failedState: String? { get }

    func continueButtonTapped()
}

class WelcomeViewModel: WelcomeViewModelProtocol {
    @Published var scrollOrder = 0  // ✅ Add scrollOrder back
    @Published var showLoadingView = false
    @Published var emergencyConnectStatus = false
    @Published var failedState: String? = nil

    let routeToSignup = PassthroughSubject<Bool, Never>()
    let routeToMainView = PassthroughSubject<Bool, Never>()
    let routeToLogin = PassthroughSubject<Bool, Never>()
    let routeToEmergency = PassthroughSubject<Bool, Never>()

    private var cancellables = Set<AnyCancellable>()
    private let userRepository: UserRepository
    private let keyChainDatabase: KeyChainDatabase
    private let userDataRepository: UserDataRepository
    private let apiManager: APIManager
    private let preferences: Preferences
    private let vpnManager: VPNManager
    private let logger: FileLogger

    init(userRepository: UserRepository,
         keyChainDatabase: KeyChainDatabase,
         userDataRepository: UserDataRepository,
         apiManager: APIManager,
         preferences: Preferences,
         vpnManager: VPNManager,
         logger: FileLogger) {
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
            }, receiveValue: { [weak self] session in
                guard let self = self else { return }
                self.keyChainDatabase.setGhostAccountCreated()
                self.userRepository.login(session: session)
                self.logger.logI(WelcomeViewModel.self, "Ghost account registration successful")
                self.prepareUserData()
            })
            .store(in: &cancellables)
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
        self.routeToSignup.send(true)
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

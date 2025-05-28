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

protocol WelcomeViewModel: ObservableObject {
    var scrollOrder: Int { get set }
    var showLoadingView: Bool { get }
    var routeToMainView: PassthroughSubject<Bool, Never> { get }
    var routeToSignup: PassthroughSubject<Bool, Never> { get }
    var emergencyConnectStatus: Bool { get }
    var failedState: String? { get }

    func continueWithAppleTapped()
}

class WelcomeViewModelImpl: WelcomeViewModel {

    @Published var scrollOrder = 0
    @Published var showLoadingView = false
    @Published var emergencyConnectStatus = false
    @Published var failedState: String?

    let routeToSignup = PassthroughSubject<Bool, Never>()
    let routeToMainView = PassthroughSubject<Bool, Never>()

    // Image Assets
    let backgroundImage = ImagesAsset.Welcome.background
    let iconImage = ImagesAsset.Welcome.icon
    let tabInfoImages = [
        ImagesAsset.Welcome.tabInfo1,
        ImagesAsset.Welcome.tabInfo2,
        ImagesAsset.Welcome.tabInfo3,
        ImagesAsset.Welcome.tabInfo4
    ]
    let signupAppleImage = ImagesAsset.Welcome.appleIcon

    // Text Assets
    let tabInfoTexts = [
        TextsAsset.Welcome.tabInfo1,
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
    private let vpnManager: VPNManager
    private let ssoManager: SSOManaging
    private let logger: FileLogger

    private var presentingController: UIViewController?

    init(userRepository: UserRepository,
         keyChainDatabase: KeyChainDatabase,
         userDataRepository: UserDataRepository,
         apiManager: APIManager,
         preferences: Preferences,
         vpnManager: VPNManager,
         ssoManager: SSOManaging,
         logger: FileLogger) {
        self.userRepository = userRepository
        self.keyChainDatabase = keyChainDatabase
        self.userDataRepository = userDataRepository
        self.apiManager = apiManager
        self.preferences = preferences
        self.vpnManager = vpnManager
        self.ssoManager = ssoManager
        self.logger = logger

        listenForVPNStateChange()
    }

    func continueWithAppleTapped() {
        showLoadingView = true
        ssoManager.getSession()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.showLoadingView = false
                if case .failure(let error) = completion {
                    self.logger.logI("WelcomeViewModel", "Apple sign in error: \(error)")
                    self.handleError(error)
                }
            }, receiveValue: { [weak self] session in
                guard let self = self else { return }
                self.userRepository.login(session: session)
                self.logger.logI("WelcomeViewModel", "Apple sign in successful")
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
                self.logger.logD("WelcomeViewModel", "User data is ready")
                self.routeToMainView.send(true)
            })
            .store(in: &cancellables)
    }

    private func handleError(_ error: Error) {
        logger.logE("WelcomeViewModel", "Failed to login: \(error.localizedDescription)")
        showLoadingView = false

        if let error = error as? Errors {
            switch error {
            case let Errors.apiError(apiError):
                // API errors
                failedState = apiError.errorMessage ?? TextsAsset.unknownAPIError
            default:
                // Networking(Wsnet) + Apple Authorization
                failedState = error.description
            }
        }
    }

    private func listenForVPNStateChange() {
        vpnManager.vpnInfo
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] vpnInfo in
                guard let self = self else { return }
                self.emergencyConnectStatus = vpnInfo?.status == .connected
            })
            .store(in: &cancellables)
    }

    func slideScrollView() {
        scrollOrder = (scrollOrder + 1) % 4
    }
}

// MARK: Navigation type action

extension WelcomeViewModelImpl {

    func setPresentingController(_ controller: UIViewController) {
        self.presentingController = controller
    }
}

//
//  WelcomeScreenViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 11/06/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Observation
import UIKit

@available(iOS 17.0, *)
@Observable
@MainActor
final class WelcomeScreenViewModel {

    // MARK: - State (read by the view)
    var scrollOrder = 0
    var showLoadingView = false
    var emergencyConnectStatus = false
    var failedState: String?
    var routeToSignup = false
    var routeToMainView = false
    var showRestrictiveNetworkModal = false
    var isNavigating: Bool = false
    var isEmergencyConnectPresented = false
    var navigationRoute: AuthenticationRouteID? {
        didSet {
            isNavigating = navigationRoute != nil
        }
    }

    // MARK: - Dependencies (injected via init — protocols only)

    private let userDataProviding: any UserDataProviding
    private let preferencesReading: any PreferencesReading
    private let preferencesWriting: any PreferencesWriting
    private let vpnConnecting: any VPNConnecting
    private let ssoManaging: any SSOManaging
    private let logger: any LogStoring

    // MARK: - Private vars

    private var presentingController: UIViewController?

    // MARK: - Image Assets
    let tabInfoImages = [
        ImagesAsset.Welcome.tabInfo1,
        ImagesAsset.Welcome.tabInfo2,
        ImagesAsset.Welcome.tabInfo3,
        ImagesAsset.Welcome.tabInfo4
    ]

    // Text Assets
    let tabInfoTexts = [
        TextsAsset.Welcome.tabInfo1,
        TextsAsset.Welcome.tabInfo2,
        TextsAsset.Welcome.tabInfo3,
        TextsAsset.Welcome.tabInfo4
    ]

    // MARK: - Init

    init(userDataProviding: any UserDataProviding,
         preferencesReading: any PreferencesReading,
         preferencesWriting: any PreferencesWriting,
         vpnConnecting: any VPNConnecting,
         ssoManaging: any SSOManaging,
         logger: any LogStoring) {
        self.userDataProviding = userDataProviding
        self.vpnConnecting = vpnConnecting
        self.preferencesReading = preferencesReading
        self.preferencesWriting = preferencesWriting
        self.ssoManaging = ssoManaging
        self.logger = logger
    }

    // MARK: - Actions (called by the view)

    func slideScrollView() {
        scrollOrder = (scrollOrder + 1) % 4
    }


    func setPresentingController(_ controller: UIViewController) {
        self.presentingController = controller
    }

    func navigate(to destination: AuthenticationRouteID) {
        switch destination {
        case .emergency:
            isEmergencyConnectPresented = true
        default:
            navigationRoute = destination
        }
    }

    func continueWithAppleTapped() {
        Task {
            showLoadingView = true

            do {
                try await ssoManaging.getSession()
                // Save SSO provider for password reset feature
                preferencesWriting.saveSSOProvider(provider: "apple")
                logger.logI("WelcomeViewModel", "Apple sign in successful")
                await prepareUserData()
            } catch {
                logger.logE("WelcomeViewModel", "Apple sign in error: \(error)")
                handleError(error)
                showLoadingView = false
            }
        }
    }

    func observeConnectionState() async {
        for await isConnected in vpnConnecting.isConnected {
            self.emergencyConnectStatus = isConnected
        }
    }

    private func prepareUserData() async {
        do {
            try await userDataProviding.prepareUserData()
            await MainActor.run {
                showLoadingView = false
                routeToMainView = true
            }
        } catch {
            await MainActor.run {
                showLoadingView = false
                handleError(error)
            }
        }
    }

    private func handleError(_ error: Error) {
        logger.logE("WelcomeViewModel", "Failed to login: \(error.localizedDescription)")
        showLoadingView = false

        if let error = error as? Errors {
            switch error {
            case Errors.failOverFailed:
                failedState = TextsAsset.failedToLoadData
                showRestrictiveNetworkModal = true
            case let Errors.apiError(apiError):
                // API errors
                failedState = apiError.errorMessage ?? TextsAsset.unknownAPIError
            default:
                // Networking(Wsnet) + Apple Authorization
                failedState = error.description
            }
        }
    }
}

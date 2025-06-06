//
//  GhostAccountView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-09.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct GhostAccountView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeDefaultRange) private var dynamicTypeRange

    @StateObject private var viewModel: GhostAccountViewModelImpl
    @StateObject private var router: AuthenticationNavigationRouter
    @State private var showUpgradeModal = false

    init(viewModel: any GhostAccountViewModel, router: AuthenticationNavigationRouter) {
        guard let model = viewModel as? GhostAccountViewModelImpl else {
            fatalError("Ghost Account View must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {

            VStack {
                Spacer()

                Text(TextsAsset.Account.ghostInfo)
                    .font(.text(.body))
                    .dynamicTypeSize(dynamicTypeRange)
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer()

                if viewModel.isUserPro {
                    Button(action: {
                        showUpgradeModal = true
                    },label: {
                        Text(TextsAsset.signUp)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.loginRegisterEnabledButtonColor)
                            .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                            .font(.bold(.title3))
                            .dynamicTypeSize(dynamicTypeRange)
                            .clipShape(Capsule())
                    })
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
                } else {
                    NavigationLink(
                        destination: router.createView(for: .signup(claimGhostAccount: true)),
                        isActive: $router.shouldNavigateToSignup
                    ) {
                        Button(action: {
                            router.shouldNavigateToSignup = true
                        },label: {
                            Text(TextsAsset.signUp)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.loginRegisterEnabledButtonColor)
                                .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                                .font(.bold(.title3))
                                .dynamicTypeSize(dynamicTypeRange)
                                .clipShape(Capsule())
                        })
                        .padding(.horizontal, 28)
                        .padding(.bottom, 12)
                    }
                }

                NavigationLink(
                    destination: router.createView(for: .login),
                    isActive: $router.shouldNavigateToLogin
                ) {
                    Button(action: {
                        router.shouldNavigateToLogin = true
                    },label: {
                        Text(TextsAsset.login)
                            .foregroundColor(.welcomeButtonTextColor)
                            .font(.bold(.title3))
                            .dynamicTypeSize(dynamicTypeRange)
                    })
                    .padding(.bottom, 24)
                }

            }
            .padding(.top, 1)
            .dynamicTypeSize(dynamicTypeRange)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(TextsAsset.Account.title)
            .sheet(isPresented: $showUpgradeModal) {
                PlanUpgradeViewControllerWrapper()
            }
        }
    }
}

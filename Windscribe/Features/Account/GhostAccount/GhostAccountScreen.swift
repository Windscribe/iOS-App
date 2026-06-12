//
//  GhostAccountScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-09.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

/// Top-level navigation destination for Ghost Account preferences. Reads
/// `@Environment`, constructs the view model, hands it to the inner view.
@available(iOS 17.0, *)
struct GhostAccountScreen: View {
    @Environment(\.hapticFeedback) private var hapticFeedback
    @Environment(\.sessionProviding) private var sessionProvider

    let openLogin: () -> Void
    let openSignupGhost: () -> Void

    init(openLogin: @escaping () -> Void = { },
         openSignupGhost: @escaping () -> Void = { }) {
        self.openLogin = openLogin
        self.openSignupGhost = openSignupGhost
    }

    var body: some View {
        let viewModel = GhostAccountScreenViewModel(
            hapticFeedback: hapticFeedback,
            sessionProvider: sessionProvider
        )

        GhostAccountContentView(
            viewModel: viewModel,
            openLogin: openLogin,
            openSignupGhost: openSignupGhost
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(TextsAsset.Account.title)
    }
}

@available(iOS 17.0, *)
private struct GhostAccountContentView: View {
    @Environment(\.dynamicTypeDefaultRange) private var dynamicTypeRange
    @Environment(\.lookAndFeel) private var lookAndFeel

    @State private var viewModel: GhostAccountScreenViewModel
    @State private var showUpgradeModal = false

    let openLogin: () -> Void
    let openSignupGhost: () -> Void

    init(viewModel: GhostAccountScreenViewModel,
         openLogin: @escaping () -> Void,
         openSignupGhost: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.openLogin = openLogin
        self.openSignupGhost = openSignupGhost
    }

    var body: some View {
        BaseContentView {
            VStack {
                Spacer()

                Text(TextsAsset.Account.ghostInfo)
                    .font(.text(.body))
                    .dynamicTypeSize(dynamicTypeRange)
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer()

                signUpButton
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)

                loginButton
                    .padding(.bottom, 24)
            }
            .padding(.top, 1)
            .dynamicTypeSize(dynamicTypeRange)
        }
        .sheet(isPresented: $showUpgradeModal) {
            PlanUpgradeViewControllerWrapper()
        }
        .task {
            await viewModel.startObservers()
        }
    }

    private var signUpButton: some View {
        Button {
            viewModel.actionSelected()
            if viewModel.isUserPro {
                showUpgradeModal = true
            } else {
                openSignupGhost()
            }
        } label: {
            Text(TextsAsset.signUp)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.loginRegisterEnabledButtonColor)
                .foregroundColor(.from(.actionBackgroundColor, lookAndFeel.isDarkMode))
                .font(.bold(.title3))
                .dynamicTypeSize(dynamicTypeRange)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var loginButton: some View {
        Button {
            viewModel.actionSelected()
            openLogin()
        } label: {
            Text(TextsAsset.login)
                .foregroundColor(.welcomeButtonTextColor)
                .font(.bold(.title3))
                .dynamicTypeSize(dynamicTypeRange)
        }
        .buttonStyle(.plain)
    }
}

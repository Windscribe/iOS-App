//
//  PreferencesMainScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct PreferencesMainScreen: View {
    @Environment(\.accountManaging) private var accountManaging
    @Environment(\.hapticFeedback) private var hapticFeedback
    @Environment(\.languageStoring) private var languageStoring
    @Environment(\.logger) private var logger
    @Environment(\.lookAndFeel) private var lookAndFeel
    @Environment(\.sessionProviding) private var sessionProviding

    var body: some View {
        let viewModel = PreferencesMainViewModel(
            accountManaging: accountManaging,
            hapticFeedback: hapticFeedback,
            languageStoring: languageStoring,
            logger: logger,
            sessionProviding: sessionProviding
        )

        PreferencesMainContentView(viewModel: viewModel)
    }
}

@available(iOS 17.0, *)
private struct PreferencesMainContentView: View {
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange
    @Environment(\.lookAndFeel) private var lookAndFeel

    @State private var viewModel: PreferencesMainViewModel
    @State private var activeRoute: PreferencesRouteID?
    @State private var showConfirmEmailSheet = false
    @State private var showLogoutConfirmation = false

    init(viewModel: PreferencesMainViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        BaseContentView {
            VStack(spacing: 16) {
                ScrollView {
                    VStack(spacing: 14) {
                        categoryRows
                    }
                    .padding(.top, 8)
                }

                actionButtons
            }
        }
        .background(routeLink)
        .edgesIgnoringSafeArea(.bottom)
        .dynamicTypeSize(dynamicTypeRange)
        .sheet(isPresented: $showConfirmEmailSheet) {
            confirmEmailSheetContent
        }
        .alert(TextsAsset.Preferences.logout, isPresented: $showLogoutConfirmation) {
            Button(TextsAsset.cancel, role: .cancel) { }
            Button(TextsAsset.Preferences.logout, role: .destructive) {
                viewModel.logout()
            }
        } message: {
            Text(TextsAsset.Preferences.logOutAlert)
        }
        .task {
            await viewModel.startObservers()
        }
    }

    @ViewBuilder
    private var categoryRows: some View {
        ForEach(viewModel.visibleItems, id: \.self) { item in
            if !viewModel.shouldHideRow(item: item) {
                Button {
                    viewModel.actionSelected()
                    if item == .logout {
                        showLogoutConfirmation = true
                    } else if let route = viewModel.route(for: item) {
                        activeRoute = route
                    }
                } label: {
                    MenuCategoryRow(item: item)
                }
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.actionDisplay != .hideAll {
                PreferencesActionButton(
                    title: actionButtonTitle,
                    backgroundColor: .unconfirmedYellow,
                    textColor: .midnight,
                    icon: Image(ImagesAsset.warningBlack),
                    action: handlePrimaryAction
                )
            }

            if viewModel.actionDisplay == .setupAccountAndLogin || viewModel.actionDisplay == .setupAccount {
                PreferencesActionButton(
                    title: TextsAsset.login,
                    backgroundColor: .from(.actionBackgroundColor, lookAndFeel.isDarkMode),
                    textColor: .from(.titleColor, lookAndFeel.isDarkMode),
                    icon: nil,
                    action: {
                        viewModel.actionSelected()
                        activeRoute = .login
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    @ViewBuilder
    private var confirmEmailSheetContent: some View {
        ConfirmEmailScreen(
            openEnterEmail: {
                showConfirmEmailSheet = false
                activeRoute = .enterEmail
            },
            onDismiss: {
                showConfirmEmailSheet = false
            }
        )
        .presentationDetents([PresentationDetent.fraction(0.65)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
        .presentationBackground {
            Color.from(.screenBackgroundColor, lookAndFeel.isDarkMode)
                .padding(.bottom, -1000)
        }
    }

    @ViewBuilder
    private var routeLink: some View {
        NavigationLink(
            destination: routeDestination,
            isActive: Binding(
                get: { activeRoute != nil },
                set: { isActive in
                    if !isActive {
                        activeRoute = nil
                    }
                }
            )
        ) {
            EmptyView()
        }
        .hidden()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var routeDestination: some View {
        if let route = activeRoute {
            switch route {
            case .general:
                GeneralScreen()
            case .account:
                AccountScreen {
                    activeRoute = .enterEmail
                }
            case .connection:
                ConnectionScreen()
            case .robert:
                RobertScreen()
            case .referData:
                ReferForDataScreen()
            case .lookAndFeel:
                LookAndFeelScreen()
            case .help:
                HelpMeScreen()
            case .about:
                AboutScreen()
            case .screenTest:
                ScreenTestScreen()
            case .ghostAccount:
                GhostAccountScreen(
                    openLogin: { activeRoute = .login },
                    openSignupGhost: { activeRoute = .signupGhost }
                )
            case .enterEmail:
                EnterEmailScreen {
                    activeRoute = nil
                }
            case .login, .signupGhost:
                PreferencesNavigationRouter().createView(for: route)
            }
        } else {
            EmptyView()
        }
    }

    private var actionButtonTitle: String {
        switch viewModel.actionDisplay {
        case .email:
            TextsAsset.addEmail
        case .emailGet10GB:
            "\(TextsAsset.addEmail) (\(TextsAsset.get10GbAMonth))"
        case .setupAccount:
            TextsAsset.setupAccount
        case .confirmEmail:
            TextsAsset.EmailView.confirmEmail
        default:
            ""
        }
    }

    private func handlePrimaryAction() {
        viewModel.actionSelected()
        switch viewModel.actionDisplay {
        case .email, .emailGet10GB:
            activeRoute = .enterEmail
        case .setupAccountAndLogin, .setupAccount:
            activeRoute = .signupGhost
        case .confirmEmail:
            showConfirmEmailSheet = true
        default:
            break
        }
    }
}

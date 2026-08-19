//
//  PreferencesMainScreen.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-25.
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

    init(viewModel: PreferencesMainViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        BaseContentView {
            VStack(spacing: 16) {
                ScrollView {
                    VStack(spacing: 14) {
                        preferenceRows
                    }
                    .padding(.top, 8)
                }

                actionButtons
            }
        }
        .background(routeLink)
        .edgesIgnoringSafeArea(.bottom)
        .dynamicTypeSize(dynamicTypeRange)
        .sheet(isPresented: $viewModel.showConfirmEmailSheet) {
            confirmEmailSheetContent
        }
        .alert(TextsAsset.Preferences.logout, isPresented: $viewModel.showLogoutConfirmation) {
            Button(TextsAsset.cancel, role: .cancel) { }
            Button(TextsAsset.Preferences.logout, role: .destructive) {
                viewModel.logout()
            }
        } message: {
            Text(TextsAsset.Preferences.logOutAlert)
        }
        .allowsHitTesting(!viewModel.isLoggingOut)
        .task(id: viewModel.isLoggingOut) {
            guard !viewModel.isLoggingOut else { return }
            await viewModel.startObservers()
        }
    }

    @ViewBuilder
    private var preferenceRows: some View {
        ForEach(viewModel.visibleItems, id: \.id) { item in
            if !viewModel.shouldHideRow(item: item) {
                MenuEntryView(item: item) { _ in
                    viewModel.handleEntrySelection(item)
                }
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.actionButtons, id: \.id) { actionType in
                PreferencesActionButton(
                    actionType: actionType,
                    action: { viewModel.handlePrimaryAction(for: actionType) }
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
                viewModel.clearEmailSheet()
                viewModel.handlePrimaryAction(for: .email)
            },
            onDismiss: {
                viewModel.clearEmailSheet()
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
                get: { viewModel.activeRoute != nil },
                set: { isActive in
                    if !isActive {
                        viewModel.clearActiveRoute()
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
        if let route = viewModel.activeRoute {
            switch route {
            case .general:
                GeneralScreen()
            case .account:
                AccountScreen {
                    viewModel.handlePrimaryAction(for: .email)
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
                    openLogin: { viewModel.handlePrimaryAction(for: .login) },
                    openSignupGhost: {  viewModel.handlePrimaryAction(for: .setupAccount) }
                )
            case .enterEmail:
                EnterEmailScreen {
                    viewModel.clearActiveRoute()
                }
            case .login, .signupGhost:
                PreferencesNavigationRouter().createView(for: route)
            }
        } else {
            EmptyView()
        }
    }
}

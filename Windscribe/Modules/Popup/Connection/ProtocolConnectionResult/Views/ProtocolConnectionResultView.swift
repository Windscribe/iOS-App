//
//  ProtocolConnectionResultView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct ProtocolConnectionResultView: View, ResponsivePopupLayoutProvider {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange
    @EnvironmentObject private var context: ProtocolConnectionResultContext

    @StateObject private var viewModel: ProtocolConnectionResultViewModelImpl
    @StateObject private var router: ProtocolSwitchNavigationRouter

    init(viewModel: any ProtocolConnectionResultViewModel, router: ProtocolSwitchNavigationRouter) {
        guard let model = viewModel as? ProtocolConnectionResultViewModelImpl else {
            fatalError("ProtocolConnectionResultView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        GeometryReader { geometry in
            let topSpacer = getTopSpacerHeight(for: geometry, deviceType: deviceType)
            let bottomPadding = getBottomPadding(for: geometry, deviceType: deviceType)
            let maxWidth = getMaxWidth(for: geometry)

            mainContent(
                topSpacer: topSpacer,
                bottomPadding: bottomPadding,
                maxWidth: maxWidth
            )
        }
    }

    private func mainContent(topSpacer: CGFloat, bottomPadding: CGFloat, maxWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            headerSection(topSpacer: topSpacer, maxWidth: maxWidth)
            Spacer()
            actionButtonsSection(maxWidth: maxWidth)
            cancelButtonSection(bottomPadding: bottomPadding, maxWidth: maxWidth)
        }
        .padding(.horizontal, 48)
        .dynamicTypeSize(dynamicTypeRange)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView)
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .onChange(of: viewModel.shouldNavigateToLogCompleted) { shouldNavigate in
            if shouldNavigate {
                router.navigate(to: .protocolConnectionDebug)
            }
        }
        .overlay(routeLink)
        .onAppear {
            viewModel.updateFromContext(context)
        }
    }

    /// Top section with warning icon, title, and description
    /// Content changes based on success vs failure scenario
    private func headerSection(topSpacer: CGFloat, maxWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: topSpacer - 48)

            headerIcon
            headerTitle(maxWidth: maxWidth)
            headerDescription(maxWidth: maxWidth)
        }
    }

    private var headerIcon: some View {
        Image(ImagesAsset.windscribeWarning)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 86, height: 86)
            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
    }

    private func headerTitle(maxWidth: CGFloat) -> some View {
        Text(viewModel.titleText)
            .font(.bold(.title2))
            .dynamicTypeSize(dynamicTypeRange)
            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
            .multilineTextAlignment(.center)
            .frame(maxWidth: maxWidth)
    }

    private func headerDescription(maxWidth: CGFloat) -> some View {
        Text(viewModel.descriptionText)
            .font(.text(.callout))
            .dynamicTypeSize(dynamicTypeRange)
            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
            .opacity(0.5)
            .multilineTextAlignment(.center)
            .frame(maxWidth: maxWidth)
    }

    /// Action buttons that change based on success vs failure scenario
    /// Success: Shows "Set as Preferred" button
    /// Failure: Shows "Send Debug Log" button with loading state
    private func actionButtonsSection(maxWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            // Set as Preferred button (shown for successful connections)
            if viewModel.showSetPreferredButton {
                setPreferredButton(maxWidth: maxWidth)
            }

            // Send Debug Log button (shown for failed connections)
            if viewModel.showSendDebugLogButton {
                sendDebugLogButton(maxWidth: maxWidth)
            }
        }
    }

    /// "Set as Preferred" button for successful protocol connections
    /// This allows users to save the working protocol as preferred for the current network
    private func setPreferredButton(maxWidth: CGFloat) -> some View {
        Button(action: viewModel.setAsPreferred) {
            Text(TextsAsset.SetPreferredProtocolPopup.action)
                .font(.bold(.callout))
                .dynamicTypeSize(dynamicTypeRange)
                .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.loginRegisterEnabledButtonColor)
                .clipShape(Capsule())
        }
        .frame(maxWidth: maxWidth)
    }

    /// "Send Debug Log" button for failed protocol connections
    /// Shows loading state during log submission process
    private func sendDebugLogButton(maxWidth: CGFloat) -> some View {
        Button(action: viewModel.submitDebugLog) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .from(.actionBackgroundColor, viewModel.isDarkMode)))
                }

                Text(getDebugLogButtonText())
                    .font(.bold(.callout))
                    .dynamicTypeSize(dynamicTypeRange)
                    .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(getDebugLogButtonBackground())
            .clipShape(Capsule())
        }
        .frame(maxWidth: maxWidth)
        .disabled(viewModel.isLoading)
    }

    /// Returns appropriate text for debug log button based on current state
    private func getDebugLogButtonText() -> String {
        switch viewModel.submitLogState {
        case .initial:
            return TextsAsset.AutoModeFailedToConnectPopup.sendDebugLog
        case .sending:
            return TextsAsset.Debug.sendingAction
        case .sent:
            return TextsAsset.Debug.sentStatus
        case .failed:
            return TextsAsset.Debug.retryAction
        }
    }

    /// Returns appropriate background color for debug log button based on state
    private func getDebugLogButtonBackground() -> Color {
        switch viewModel.submitLogState {
        case .initial, .failed:
            return Color.loginRegisterEnabledButtonColor
        case .sending:
            return Color.loginRegisterEnabledButtonColor.opacity(0.6)
        case .sent:
            return Color.seaGreen
        }
    }

    /// Bottom cancel button that resets failure counts and dismisses the dialog
    private func cancelButtonSection(bottomPadding: CGFloat, maxWidth: CGFloat) -> some View {
        Button(action: viewModel.cancel) {
            Text(TextsAsset.cancel)
                .font(.bold(.callout))
                .dynamicTypeSize(dynamicTypeRange)
                .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                .opacity(0.5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .frame(maxWidth: maxWidth)
        .padding(.bottom, bottomPadding)
    }

    private var backgroundView: some View {
        Color.from(.screenBackgroundColor, viewModel.isDarkMode)
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var routeLink: some View {
        NavigationLink(
            destination: routeDestination,
            isActive: Binding(
                get: { router.activeRoute != nil },
                set: { newValue in
                    if !newValue {
                        router.pop()
                    }
                }
            )
        ) {
            EmptyView()
        }
        .hidden()
    }

    @ViewBuilder
    private var routeDestination: some View {
        if let route = router.activeRoute {
            router.createView(for: route)
        } else {
            EmptyView()
        }
    }
}

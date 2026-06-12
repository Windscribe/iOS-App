//
//  ProtocolConnectionDebugView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

/// Debug log completion screen
/// Shows success message after debug log has been submitted
/// Provides options to contact support or dismiss
struct ProtocolConnectionDebugView: View, ResponsivePopupLayoutProvider {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: ProtocolConnectionDebugViewModelImpl
    @StateObject private var router: ProtocolSwitchNavigationRouter

    init(viewModel: any ProtocolConnectionDebugViewModel, router: ProtocolSwitchNavigationRouter) {
        guard let model = viewModel as? ProtocolConnectionDebugViewModelImpl else {
            fatalError("ProtocolConnectionDebugView must be initialized properly")
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
            contactSupportSection(maxWidth: maxWidth)
            cancelButtonSection(bottomPadding: bottomPadding, maxWidth: maxWidth)
        }
        .padding(.horizontal, 48)
        .dynamicTypeSize(dynamicTypeRange)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView)
        .onChange(of: viewModel.shouldDismissCurrentView) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .onChange(of: viewModel.shouldDismissAllViews) { shouldDismissAll in
            if shouldDismissAll {
                router.pop() // Clear the navigation stack
                dismiss()    // Then dismiss the entire flow
            }
        }
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url)
        }
        .overlay(routeLink)
    }

    /// Top section with success icon and completion message
    private func headerSection(topSpacer: CGFloat, maxWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: topSpacer - 48)
            successIcon
            headerMessage(maxWidth: maxWidth)
        }
    }

    private var successIcon: some View {
        Image(ImagesAsset.checkCircleGreen)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 86, height: 86)
            .foregroundColor(.seaGreen)
    }

    private func headerMessage(maxWidth: CGFloat) -> some View {
        Text(viewModel.completionMessage)
            .font(.text(.callout))
            .dynamicTypeSize(dynamicTypeRange)
            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
            .opacity(0.5)
            .multilineTextAlignment(.center)
            .frame(maxWidth: maxWidth)
    }

    /// Contact support button for users who need assistance
    private func contactSupportSection(maxWidth: CGFloat) -> some View {
        Button(action: viewModel.contactSupport) {
            Text(TextsAsset.AutoModeFailedToConnectPopup.contactSupport)
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

    /// Bottom cancel button that dismisses the completion screen
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

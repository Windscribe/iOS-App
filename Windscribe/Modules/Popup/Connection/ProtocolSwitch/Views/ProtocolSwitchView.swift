//
//  ProtocolSwitchView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct ProtocolSwitchView: View, ResponsivePopupLayoutProvider {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange
    @EnvironmentObject private var context: ProtocolSwitchContext

    @StateObject private var viewModel: ProtocolSwitchViewModelImpl
    @StateObject private var router: ProtocolSwitchNavigationRouter

    init(viewModel: any ProtocolSwitchViewModel, router: ProtocolSwitchNavigationRouter) {
        guard let model = viewModel as? ProtocolSwitchViewModelImpl else {
            fatalError("ProtocolSwitchView must be initialized properly")
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
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                closeButtonOverlay
                headerSection(topSpacer: topSpacer, maxWidth: maxWidth)
                    .padding(.horizontal, 12)
                protocolListSection(maxWidth: maxWidth)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
                cancelButtonSection(bottomPadding: bottomPadding, maxWidth: maxWidth)
            }
            .padding(.horizontal, 24)
        }
        .dynamicTypeSize(dynamicTypeRange)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView)
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .onChange(of: viewModel.shouldNavigateToResult) { navigationData in
            if let data = navigationData {
                router.navigate(to: .protocolConnectionResult, protocolName: data.protocolName, viewType: data.viewType)
                viewModel.shouldNavigateToResult = nil
            }
        }
        .overlay(routeLink)
        .onAppear {
            viewModel.fallbackType = context.fallbackType
        }
    }

    /// Top section with icon, title, and description
    /// Shows different content based on failure vs manual change scenario
    private func headerSection(topSpacer: CGFloat, maxWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: max(10, topSpacer - 120))

            headerIcon
            headerTitle(maxWidth: maxWidth)
            headerDescription(maxWidth: maxWidth)
        }
    }

    private var headerIcon: some View {
        Image(viewModel.fallbackType.getIconAsset())
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 86, height: 86)
            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
    }

    private func headerTitle(maxWidth: CGFloat) -> some View {
        Text(viewModel.fallbackType.getHeader())
            .font(.bold(.title2))
            .dynamicTypeSize(dynamicTypeRange)
            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
            .multilineTextAlignment(.center)
            .frame(maxWidth: maxWidth)
    }

    private func headerDescription(maxWidth: CGFloat) -> some View {
        Text(getDescriptionText())
            .font(.text(.callout))
            .dynamicTypeSize(dynamicTypeRange)
            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
            .opacity(0.5)
            .multilineTextAlignment(.center)
            .frame(maxWidth: maxWidth)
    }

    /// Returns appropriate description text - error description if present, otherwise fallback type description
    private func getDescriptionText() -> String {
        return viewModel.errorDescription ?? viewModel.fallbackType.getDescription()
    }

    /// Dynamic list of available protocols with their current states
    /// Each protocol shows as connected, normal, failed, or next up with countdown
    private func protocolListSection(maxWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            ForEach(viewModel.protocols) { protocolItem in
                ProtocolItemView(
                    protocolItem: protocolItem,
                    isDarkMode: viewModel.isDarkMode,
                    maxWidth: maxWidth,
                    onTap: { viewModel.selectProtocol(protocolItem) }
                )
            }
        }
    }

    /// Bottom cancel button with dynamic behavior based on connection state
    /// Connected: dismisses dialog, Disconnected: triggers disconnect and resets fail counts
    private func cancelButtonSection(bottomPadding: CGFloat, maxWidth: CGFloat) -> some View {
        Button(action: viewModel.cancelSelection) {
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

    private var closeButtonOverlay: some View {
        HStack {
            Spacer()
            Button(action: viewModel.dismiss) {
                Image(ImagesAsset.closeIcon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
            }
            .frame(width: 32, height: 32)
            .padding(.top, 24)
        }
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

/// Represents a single protocol option with different visual states
/// Handles connected, normal, failed, and nextUp states with appropriate UI indicators
struct ProtocolItemView: View {
    let protocolItem: ProtocolDisplayItem
    let isDarkMode: Bool
    let maxWidth: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            if protocolItem.viewType.isSelectable {
                onTap()
            }
        },label: {
            protocolContentView
        })
        .disabled(!protocolItem.viewType.isSelectable)
    }

    private var protocolContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            protocolHeaderRow
            protocolDescriptionRow
        }
        .padding(16)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .background(protocolBackgroundView)
        .overlay(protocolBorderView)
        .overlay(protocolStateOverlay, alignment: .topTrailing)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// Top row showing protocol name, port, status indicator, and countdown if applicable
    private var protocolHeaderRow: some View {
        HStack {
            protocolNameSection
            Spacer()
            protocolStatusSection
        }
    }

    private var protocolNameSection: some View {
        HStack(spacing: 8) {
            // Protocol name (e.g., "WIREGUARD")
            Text(protocolItem.displayName)
                .font(.bold(.callout))
                .foregroundColor(.from(.iconColor, isDarkMode))

            Rectangle()
                .fill(Color.from(.iconColor, isDarkMode))
                .opacity(0.2)
                .frame(width: 1, height: 16)

            // Port name (e.g., "443")
            Text(protocolItem.portName)
                .font(.bold(.callout))
                .foregroundColor(.from(.iconColor, isDarkMode))
        }
    }

    @ViewBuilder
    private var protocolStatusSection: some View {
        switch protocolItem.viewType {
        case .connected:
            EmptyView()

        default:
            HStack(spacing: 8) {
                protocolStatusLabel
                protocolStatusIcon
            }
        }
    }

    /// Status label showing current protocol state or countdown
    @ViewBuilder
    private var protocolStatusLabel: some View {
        switch protocolItem.viewType {
        case .connected:
            Text(TextsAsset.ProtocolVariation.connectedState)
                .font(.text(.caption1))
                .foregroundColor(.seaGreen)

        case .fail:
            Text(TextsAsset.Status.failed.lowercased().capitalized)
                .font(.text(.caption1))
                .foregroundColor(.loginRegisterFailedField)

        default:
            EmptyView()
        }
    }

    /// Status icon showing appropriate indicator for protocol state
    @ViewBuilder
    private var protocolStatusIcon: some View {
        switch protocolItem.viewType {
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.seaGreen)
                .font(.caption)

        case .normal:
            Image(systemName: "chevron.right")
                .foregroundColor(.from(.iconColor, isDarkMode))
                .opacity(0.5)
                .font(.caption)

        default:
            EmptyView()
        }
    }

    /// Bottom row showing protocol description
    private var protocolDescriptionRow: some View {
        Text(protocolItem.description)
            .font(.text(.subheadline))
            .foregroundColor(.from(.iconColor, isDarkMode))
            .opacity(0.5)
            .multilineTextAlignment(.leading)
            .lineLimit(protocolItem.viewType == .connected ? 2 : nil)
            .padding(.trailing, protocolItem.viewType == .connected ? 60 : 30)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Background color based on protocol state
    private var protocolBackgroundView: some View {
        Color.from(.iconColor, isDarkMode).opacity(0.1)
    }

    /// Protocol state overlay positioned at top-trailing corner
    @ViewBuilder
    private var protocolStateOverlay: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Top corner badge - either "Connected to" or timer
            topCornerBadge

            Spacer().frame(height: 28)

            // Bottom right icon - checkmark for connected, arrow for nextUp with timer
            bottomRightIcon
        }
    }

    @ViewBuilder
    private var topCornerBadge: some View {
        switch protocolItem.viewType {
        case .connected:
            Text(TextsAsset.ProtocolVariation.connectedState)
                .font(.text(.caption1))
                .foregroundColor(.seaGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.seaGreen.opacity(0.2))
                )

        case let .nextUp(countDownSeconds):
            if countDownSeconds >= 0 && protocolItem.viewType.showCountdown {
                Text("\(TextsAsset.autoModeSelectorInfo) \(countDownSeconds)s")
                    .font(.text(.caption1))
                    .foregroundColor(.seaGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.seaGreen.opacity(0.2))
                    )
            }

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var bottomRightIcon: some View {
        switch protocolItem.viewType {
        case .connected:
            Image(ImagesAsset.greenCheckMark)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundColor(.seaGreen)
                .padding(.trailing, 16)

        case let .nextUp(countDownSeconds):
            if countDownSeconds >= 0 && protocolItem.viewType.showCountdown {
                Image(systemName: "chevron.right")
                    .foregroundColor(.from(.iconColor, isDarkMode))
                    .opacity(0.5)
                    .font(.caption)
                    .padding(.trailing, 16)
            }

        default:
            EmptyView()
        }
    }

    /// Border styling based on protocol state - connected shows muted green border
    @ViewBuilder
    private var protocolBorderView: some View {
        switch protocolItem.viewType {
        case .connected:
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.seaGreen.opacity(0.2), lineWidth: 2)

        default:
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.from(.iconColor, isDarkMode).opacity(0.1), lineWidth: 1)
        }
    }
}

final class ProtocolSwitchContext: ObservableObject {
    @Published var fallbackType: ProtocolFallbacksType = .change
    @Published var error: VPNConfigurationErrors?
}

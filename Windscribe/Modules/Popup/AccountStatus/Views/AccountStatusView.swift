//
//  AccountStatusView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-29.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct AccountStatusView: View, ResponsivePopupLayoutProvider {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange
    @EnvironmentObject private var context: AccountStatusContext

    @StateObject private var viewModel: AccountStatusViewModelImpl

    init(viewModel: any AccountStatusViewModel) {
        guard let model = viewModel as? AccountStatusViewModelImpl else {
            fatalError("AccountStatusView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    private func buttonBackgroundColor(isPrimary: Bool) -> Color {
        switch viewModel.accountStatusType {
        case .banned:
            // Banned has only one dismiss-type button
            return Color.from(.dismissButtonBackgroundColor, viewModel.isDarkMode)
        case .outOfData, .proPlanExpired:
            if isPrimary {
                // Primary button is action-type (upgrade/renew)
                return Color.from(.actionButtonBackgroundColor, viewModel.isDarkMode)
            } else {
                // Secondary button is dismiss-type (remind me later)
                return Color.from(.dismissButtonBackgroundColor, viewModel.isDarkMode)
            }
        }
    }

    private func buttonTextColor(isPrimary: Bool) -> Color {
        switch viewModel.accountStatusType {
        case .banned:
            // Banned has only one dismiss-type button
            return Color.from(.dismissButtonTextColor, viewModel.isDarkMode)
        case .outOfData, .proPlanExpired:
            if isPrimary {
                // Primary button is action-type (upgrade/renew)
                return Color.from(.actionButtonTextColor, viewModel.isDarkMode)
            } else {
                // Secondary button is dismiss-type (remind me later)
                return Color.from(.dismissButtonTextColor, viewModel.isDarkMode)
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let topSpacer = getTopSpacerHeight(for: geometry, deviceType: deviceType)
            let bottomPadding = getBottomPadding(for: geometry, deviceType: deviceType)
            let maxWidth = getMaxWidth(for: geometry)

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: topSpacer - 64)

                // Character Image
                Image(viewModel.accountStatusType.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)

                VStack(spacing: 25) {
                    // Title
                    Text(viewModel.accountStatusType.title)
                        .font(.bold(.title2))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: maxWidth)

                    // Description
                    VStack(spacing: 4) {
                        Text(viewModel.displayDescription)
                            .font(.regular(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .foregroundColor(.welcomeButtonTextColor)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: maxWidth)

                        if !viewModel.resetDate.isEmpty {
                            Text(viewModel.resetDate)
                                .font(.regular(.callout))
                                .dynamicTypeSize(dynamicTypeRange)
                                .foregroundColor(Color.from(.dismissButtonTextColor, viewModel.isDarkMode))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: maxWidth)
                        }
                    }
                }
                .padding(.bottom, 25)

                VStack(spacing: 16) {
                    // Primary Action Button
                    Button(action: viewModel.primaryAction) {
                        Text(viewModel.accountStatusType.primaryButtonTitle)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(buttonBackgroundColor(isPrimary: true))
                            .foregroundColor(buttonTextColor(isPrimary: true))
                            .font(.bold(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .clipShape(Capsule())
                    }
                    .disabled(!viewModel.accountStatusType.canTakeAction)
                    .frame(maxWidth: maxWidth)

                    // Secondary Action Button (if available)
                    if let secondaryTitle = viewModel.accountStatusType.secondaryButtonTitle {
                        Button(action: viewModel.secondaryAction) {
                            Text(secondaryTitle)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(buttonBackgroundColor(isPrimary: false))
                                .foregroundColor(buttonTextColor(isPrimary: false))
                                .font(.bold(.callout))
                                .dynamicTypeSize(dynamicTypeRange)
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: maxWidth)
                    }
                }

                Spacer()
                    .frame(height: bottomPadding + 96)
            }
            .dynamicTypeSize(dynamicTypeRange)
            .padding(.horizontal, 64)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.from(.screenBackgroundColor, viewModel.isDarkMode).ignoresSafeArea())
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .sheet(isPresented: $viewModel.showUpgrade) {
            PlanUpgradeViewControllerWrapper()
        }
        .onAppear {
            viewModel.updateAccountStatusType(context.accountStatusType)
        }
        .onChange(of: context.accountStatusType) { newType in
            viewModel.updateAccountStatusType(newType)
        }
    }
}

final class AccountStatusContext: ObservableObject {
    @Published var accountStatusType: AccountStatusType = .banned
}

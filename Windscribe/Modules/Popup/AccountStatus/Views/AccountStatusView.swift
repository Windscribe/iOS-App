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

    var body: some View {
        GeometryReader { geometry in
            let topSpacer = getTopSpacerHeight(for: geometry, deviceType: deviceType)
            let bottomPadding = getBottomPadding(for: geometry, deviceType: deviceType)
            let maxWidth = getMaxWidth(for: geometry)

            VStack(spacing: 32) {
                Spacer()
                    .frame(height: topSpacer - 64)

                // Character Image
                Image(viewModel.accountStatusType.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)

                VStack(spacing: 16) {
                    // Title
                    Text(viewModel.accountStatusType.title)
                        .font(.bold(.title2))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: maxWidth)

                    // Description
                    Text(viewModel.displayDescription)
                        .font(.text(.callout))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.welcomeButtonTextColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: maxWidth)
                }

                VStack(spacing: 8) {
                    // Primary Action Button
                    Button(action: viewModel.primaryAction) {
                        Text(viewModel.accountStatusType.primaryButtonTitle)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.accountStatusType.canTakeAction ? Color.loginRegisterEnabledButtonColor : Color.gray)
                            .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
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
                                .foregroundColor(.welcomeButtonTextColor)
                                .font(.bold(.callout))
                                .dynamicTypeSize(dynamicTypeRange)
                        }
                        .frame(maxWidth: maxWidth)
                    }
                }

                Spacer()
                    .frame(height: bottomPadding)
            }
            .dynamicTypeSize(dynamicTypeRange)
            .padding(.horizontal, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color.from(.screenBackgroundColor, viewModel.isDarkMode)
                    .opacity(0.95)
                    .ignoresSafeArea()
            )
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

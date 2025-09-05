//
//  LocationPermissionView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-07.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct LocationPermissionInfoView: View, ResponsivePopupLayoutProvider {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: LocationPermissionInfoViewModelImpl

    init(viewModel: any LocationPermissionInfoViewModel) {
        guard let model = viewModel as? LocationPermissionInfoViewModelImpl else {
            fatalError("LocationPermissionView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        GeometryReader { geometry in
            let topSpacer = getTopSpacerHeight(for: geometry, deviceType: deviceType)
            let bottomPadding = getBottomPadding(for: geometry, deviceType: deviceType)
            let maxWidth = getMaxWidth(for: geometry)

            ZStack {
                VStack {
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: topSpacer)

                        Image(ImagesAsset.promptInfo)
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                        Text(TextsAsset.Permission.disclaimer)
                            .font(.bold(.title2))
                            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                        Text(TextsAsset.Permission.disclosureDescription)
                            .font(.text(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .foregroundColor(.welcomeButtonTextColor)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: maxWidth)
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        Button(action: viewModel.handlePrimaryAction) {
                            Text(viewModel.accessDenied ? TextsAsset.Permission.openSettings : TextsAsset.Permission.grantPermission)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.loginRegisterEnabledButtonColor)
                                .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                                .font(.bold(.callout))
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: maxWidth)

                        Button(action: {
                            dismiss()
                        }, label: {
                            Text(TextsAsset.cancel)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.welcomeButtonTextColor)
                                .font(.bold(.callout))
                                .dynamicTypeSize(dynamicTypeRange)
                        })
                        .frame(maxWidth: maxWidth)
                    }
                    .padding(.bottom, bottomPadding)
                }
                .padding()
                .dynamicTypeSize(dynamicTypeRange)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.from(.screenBackgroundColor, viewModel.isDarkMode).ignoresSafeArea())
            .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
                if shouldDismiss {
                    dismiss()
                }
            }
            .onDisappear {
                viewModel.onDisappear()
            }
        }
    }
}

//
//  MaintananceLocationView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-24.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI
import SafariServices

struct MaintananceLocationView: View, ResponsivePopupLayoutProvider {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange
    @EnvironmentObject private var context: MaintananceLocationContext

    @StateObject private var viewModel: MaintananceLocationViewModelImpl

    init(viewModel: any MaintananceLocationViewModel) {
        guard let model = viewModel as? MaintananceLocationViewModelImpl else {
            fatalError("MaintananceLocationView must be initialized properly")
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
                    .frame(height: topSpacer)

                // Top Image - Garry character
                Image(ImagesAsset.Garry.con)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 94, height: 130)

                VStack(spacing: 16) {
                    // Header Title
                    Text(TextsAsset.MaintenanceLocationPopUp.title)
                        .font(.bold(.title2))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: maxWidth)

                    // Sub Header Text
                    Text(TextsAsset.MaintenanceLocationPopUp.subtHeader)
                        .font(.text(.body))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.welcomeButtonTextColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: maxWidth)
                }

                VStack(spacing: 8) {
                    // Check Status Button (hidden for static IP)
                    if !context.isStaticIp {
                        Button(action: viewModel.checkStatus) {
                            Text(TextsAsset.MaintenanceLocationPopUp.checkStatus)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.loginRegisterEnabledButtonColor)
                                .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                                .font(.bold(.title3))
                                .dynamicTypeSize(dynamicTypeRange)
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: maxWidth)
                    }

                    // Cancel Button
                    Button(action: viewModel.cancel) {
                        Text(TextsAsset.MaintenanceLocationPopUp.cancelTitle)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.welcomeButtonTextColor)
                            .font(.bold(.title3))
                            .dynamicTypeSize(dynamicTypeRange)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: maxWidth)
                }

                Spacer()
                    .frame(height: bottomPadding)
            }
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
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url)
        }
    }
}

final class MaintananceLocationContext: ObservableObject {
    @Published var isStaticIp = false
}

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

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: topSpacer - 64)

                // Character Image
                Image(ImagesAsset.Garry.con)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)

                VStack(spacing: 25) {
                    // Title
                    Text(TextsAsset.MaintenanceLocationPopUp.title)
                        .font(.bold(.title2))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: maxWidth)

                    // Description
                    Text(TextsAsset.MaintenanceLocationPopUp.subtHeader)
                        .font(.regular(.callout))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.welcomeButtonTextColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: maxWidth)
                }
                .padding(.bottom, 25)

                VStack(spacing: 16) {
                    // Primary Action Button (Check Status)
                    Button(action: viewModel.checkStatus) {
                        Text(TextsAsset.MaintenanceLocationPopUp.checkStatus)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.from(.actionButtonBackgroundColor, viewModel.isDarkMode))
                            .foregroundColor(Color.from(.actionButtonTextColor, viewModel.isDarkMode))
                            .font(.bold(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: maxWidth)

                    // Secondary Action Button (Cancel/Dismiss)
                    Button(action: viewModel.cancel) {
                        Text(TextsAsset.MaintenanceLocationPopUp.cancelTitle)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.from(.dismissButtonBackgroundColor, viewModel.isDarkMode))
                            .foregroundColor(Color.from(.dismissButtonTextColor, viewModel.isDarkMode))
                            .font(.bold(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: maxWidth)
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
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url, isDarkMode: viewModel.isDarkMode)
        }
    }
}

final class MaintananceLocationContext: ObservableObject {
    @Published var isStaticIp = false
}

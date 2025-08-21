//
//  RestrictiveNetworkView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-14.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct RestrictiveNetworkView: View, ResponsivePopupLayoutProvider {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: RestrictiveNetworkViewModelImpl

    init(viewModel: any RestrictiveNetworkViewModel) {
        guard let model = viewModel as? RestrictiveNetworkViewModelImpl else {
            fatalError("RestrictiveNetworkView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        GeometryReader { geometry in
            let topSpacer = getTopSpacerHeight(for: geometry, deviceType: deviceType)
            let bottomPadding = getBottomPadding(for: geometry, deviceType: deviceType)
            let maxWidth = getMaxWidth(for: geometry)

            VStack {
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: topSpacer)

                    Image(ImagesAsset.attention)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                    Text(TextsAsset.RestrictiveNetwork.title)
                        .font(.bold(.title2))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                    Text(TextsAsset.RestrictiveNetwork.description)
                        .font(.text(.callout))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.welcomeButtonTextColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: maxWidth)
                }

                Spacer()

                VStack(spacing: 8) {
                    Button(action: viewModel.exportLogs) {
                        HStack {
                            if viewModel.isExportingLogs {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .from(.actionBackgroundColor, viewModel.isDarkMode)))
                                    .scaleEffect(0.8)
                            } else {
                                Text(TextsAsset.RestrictiveNetwork.exportAction)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.loginRegisterEnabledButtonColor)
                        .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                        .font(.bold(.callout))
                        .dynamicTypeSize(dynamicTypeRange)
                        .clipShape(Capsule())
                    }
                    .disabled(viewModel.isExportingLogs)
                    .frame(maxWidth: maxWidth)

                    Button(action: viewModel.contactSupport) {
                        Text(TextsAsset.RestrictiveNetwork.supportContactsAction)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.loginRegisterEnabledButtonColor)
                            .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                            .font(.bold(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: maxWidth)

                    Button(action: viewModel.cancel) {
                        Text(TextsAsset.cancel)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.welcomeButtonTextColor)
                            .font(.bold(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                    }
                    .frame(maxWidth: maxWidth)
                }
                .padding(.bottom, bottomPadding)
            }
            .padding()
            .dynamicTypeSize(dynamicTypeRange)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.from(.screenBackgroundColor, viewModel.isDarkMode).ignoresSafeArea())
            .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
                if shouldDismiss {
                    dismiss()
                }
            }
            .sheet(item: $viewModel.safariURL) { url in
                SafariView(url: url, isDarkMode: viewModel.isDarkMode)
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                ShareSheetView(items: [viewModel.logContentToShare])
            }
        }
    }
}

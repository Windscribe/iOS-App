//
//  RestrictiveNetworkScreen.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-07-01.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct RestrictiveNetworkScreen: View {
    @Environment(\.logger) private var logger

    var body: some View {
        RestrictiveNetworkContentView(viewModel: RestrictiveNetworkScreenViewModel(logger: logger))
    }
}

@available(iOS 17.0, *)
private struct RestrictiveNetworkContentView: View, ResponsivePopupLayoutProvider {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange
    @Environment(\.lookAndFeel) private var lookAndFeel

    @State private var viewModel: RestrictiveNetworkScreenViewModel

    init(viewModel: RestrictiveNetworkScreenViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindable = viewModel

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
                        .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))

                    Text(TextsAsset.RestrictiveNetwork.title)
                        .font(.bold(.title2))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))

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
                                    .progressViewStyle(CircularProgressViewStyle(
                                        tint: .from(.actionBackgroundColor, lookAndFeel.isDarkMode)
                                    ))
                                    .scaleEffect(0.8)
                            } else {
                                Text(TextsAsset.RestrictiveNetwork.exportAction)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.loginRegisterEnabledButtonColor)
                        .foregroundColor(.from(.actionBackgroundColor, lookAndFeel.isDarkMode))
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
                            .foregroundColor(.from(.actionBackgroundColor, lookAndFeel.isDarkMode))
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
            .background(Color.from(.screenBackgroundColor, lookAndFeel.isDarkMode).ignoresSafeArea())
            .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss {
                    dismiss()
                }
            }
            .sheet(item: $bindable.safariURL) { url in
                SafariView(url: url)
            }
            .sheet(isPresented: $bindable.showShareSheet) {
                ShareSheetView(items: [viewModel.logContentToShare])
            }
        }
    }
}

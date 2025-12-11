//
//  BridgeApiFailedView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 04/11/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct BridgeApiFailedView: View, ResponsivePopupLayoutProvider {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange
    @EnvironmentObject private var context: BridgeApiFailedContext

    @StateObject private var viewModel: BridgeApiFailedViewModelImpl

    init(viewModel: any BridgeApiFailedViewModel) {
        guard let model = viewModel as? BridgeApiFailedViewModelImpl else {
            fatalError("BridgeApiFailedView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        GeometryReader { geometry in
            let topSpacer = getTopSpacerHeight(for: geometry, deviceType: deviceType)
            let maxWidth = getMaxWidth(for: geometry)

            ZStack {
                VStack {
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: topSpacer)

                        Image(viewModel.popupType.imageName)
                            .resizable()
                            .frame(width: 274, height: 217)

                        Text(viewModel.popupType.title)
                            .font(.bold(.title2))
                            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                        Text(viewModel.popupType.body)
                            .font(.text(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .foregroundColor(.welcomeButtonTextColor)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: maxWidth)
                            .padding(.horizontal, 48)
                    }
                    .padding(.bottom, 24)

                    VStack(spacing: 8) {
                        Button(action: viewModel.handlePrimaryAction) {
                            Text(viewModel.popupType.actionButtonText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.from(.dismissButtonTextColor,
                                                       viewModel.isDarkMode).opacity(0.1))
                                .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                                .font(.bold(.callout))
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: maxWidth)

                        Button(action: {
                            viewModel.handleDismissAction()
                        }, label: {
                            Text(TextsAsset.BridgeAPI.backButton)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.from(.dismissButtonTextColor,
                                                       viewModel.isDarkMode).opacity(0.1))
                                .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                                .font(.bold(.callout))
                                .dynamicTypeSize(dynamicTypeRange)
                                .clipShape(Capsule())
                        })
                        .frame(maxWidth: maxWidth)
                    }
                    .padding(.horizontal, 36)

                    Spacer()
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
            .onAppear {
                viewModel.updatePopupType(context.popupType)
            }
            .sheet(item: $viewModel.safariURL) { url in
                SafariView(url: url, isDarkMode: viewModel.isDarkMode)
            }
        }
    }
}

final class BridgeApiFailedContext: ObservableObject {
    @Published var popupType: BridgeApiPopupType = .pinIp
}

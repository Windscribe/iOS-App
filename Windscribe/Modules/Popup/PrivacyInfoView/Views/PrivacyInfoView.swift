//
//  PrivacyInfoView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct PrivacyInfoView: View, ResponsivePopupLayoutProvider {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: PrivacyInfoViewModelImpl

    init(viewModel: any PrivacyInfoViewModel) {
        guard let model = viewModel as? PrivacyInfoViewModelImpl else {
            fatalError("PrivacyInfoView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        GeometryReader { geometry in
            let bottomPadding = getBottomPadding(for: geometry, deviceType: deviceType)
            let maxWidth = getMaxWidth(for: geometry)

            ZStack {
                VStack(spacing: 32) {
                    // Privacy Description Text - Scrollable
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: true) {
                            VStack(alignment: .leading, spacing: 16) {
                                Spacer()
                                    .frame(height: 40)
                                    .id("topPadding")

                                Text(TextsAsset.PrivacyView.description)
                                    .font(.text(.subheadline))
                                    .dynamicTypeSize(dynamicTypeRange)
                                    .foregroundColor(.white)
                                    .opacity(0.5)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: maxWidth, alignment: .leading)
                                    .id("privacyText")
                            }
                        }
                        .onAppear {
                            // Very subtle scroll to show indicator
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    proxy.scrollTo("privacyText", anchor: .center)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        proxy.scrollTo("topPadding", anchor: .top)
                                    }
                                }
                            }
                        }
                    }

                    // Button positioned closer to text
                    Button(action: viewModel.acceptPrivacy) {
                        Text(TextsAsset.PrivacyView.action)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.loginRegisterEnabledButtonColor)
                            .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                            .font(.bold(.title3))
                            .dynamicTypeSize(dynamicTypeRange)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: maxWidth)
                    .padding(.bottom, bottomPadding)
                }
                .padding()
                .dynamicTypeSize(dynamicTypeRange)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color.from(.screenBackgroundColor, viewModel.isDarkMode)
                    .opacity(0.95)
                    .ignoresSafeArea()
            )
            .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
                if shouldDismiss {
                    dismiss()
                }
            }
        }
    }
}

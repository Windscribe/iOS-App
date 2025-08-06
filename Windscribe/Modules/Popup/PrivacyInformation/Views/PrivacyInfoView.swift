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
            let baseMaxWidth = getMaxWidth(for: geometry)
            let maxWidth = deviceType == .iPadPortrait || deviceType == .iPadLandscape ? 600 : baseMaxWidth

            mainContent(maxWidth: maxWidth)
        }
    }

    private func mainContent(maxWidth: CGFloat) -> some View {
        ZStack {
            contentView(maxWidth: maxWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView)
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    private func contentView(maxWidth: CGFloat) -> some View {
        VStack {
            scrollableTextView(maxWidth: maxWidth)
            Spacer()
            acceptButton(maxWidth: maxWidth)
        }
        .padding(.horizontal)
        .padding(.top)
        .dynamicTypeSize(dynamicTypeRange)
    }

    private func scrollableTextView(maxWidth: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    Spacer()
                        .frame(height: 20)
                        .id("topPadding")

                    privacyDescriptionText(maxWidth: maxWidth)
                }
            }
            .onAppear {
                // Very subtle scroll to show indicator
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        proxy.scrollTo("privacyText", anchor: UnitPoint.center)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo("topPadding", anchor: UnitPoint.top)
                        }
                    }
                }
            }
        }
    }

    private func privacyDescriptionText(maxWidth: CGFloat) -> some View {
        Text(TextsAsset.PrivacyView.description)
            .font(.text(deviceType == .iPadPortrait || deviceType == .iPadLandscape ? .body : .subheadline))
            .dynamicTypeSize(dynamicTypeRange)
            .foregroundColor(.white)
            .opacity(0.5)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .id("privacyText")
    }

    private func acceptButton(maxWidth: CGFloat) -> some View {
        Button(action: viewModel.acceptPrivacy) {
            Text(TextsAsset.PrivacyView.action)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.loginRegisterEnabledButtonColor)
                .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                .font(.bold(.callout))
                .dynamicTypeSize(dynamicTypeRange)
                .clipShape(Capsule())
        }
        .frame(maxWidth: maxWidth)
        .padding(.bottom, 12)
    }

    private var backgroundView: some View {
        Color.from(.screenBackgroundColor, viewModel.isDarkMode)
            .opacity(0.95)
            .ignoresSafeArea()
    }
}

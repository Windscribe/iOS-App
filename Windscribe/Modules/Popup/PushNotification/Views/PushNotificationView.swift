//
//  PushNotificationView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-21.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct PushNotificationView: View, ResponsivePopupLayoutProvider {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: PushNotificationViewModelImpl

    init(viewModel: any PushNotificationViewModel) {
        guard let model = viewModel as? PushNotificationViewModelImpl else {
            fatalError("PushNotificationView must be initialized properly")
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

                    Image(ImagesAsset.pushNotifications)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 90, height: 90)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                    Text(TextsAsset.PushNotifications.title)
                        .font(.bold(.title2))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                    Text(TextsAsset.PushNotifications.description)
                        .font(.text(.callout))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.welcomeButtonTextColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: maxWidth)
                }

                Spacer()

                VStack(spacing: 8) {
                    Button(action: viewModel.enableNotifications) {
                        Text(TextsAsset.PushNotifications.action)
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
        }
    }

}

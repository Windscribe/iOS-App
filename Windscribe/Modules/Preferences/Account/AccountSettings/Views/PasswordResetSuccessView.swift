//
//  PasswordResetSuccessView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-12-19.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct PasswordResetSuccessView: View {
    let isDarkMode: Bool
    let onClose: () -> Void

    var body: some View {
        PreferencesBaseView(isDarkMode: .constant(isDarkMode)) {
            VStack(spacing: 32) {
                // Green checkmark icon
                Image(ImagesAsset.checkCircleGreen)
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 120, height: 120)

                // Success message
                Text(TextsAsset.Account.resetPasswordSuccess)
                    .multilineTextAlignment(.center)
                    .font(.text(.callout))
                    .foregroundColor(.from(.infoColor, isDarkMode))
                    .padding(.horizontal, 40)

                // Close button
                Button(action: onClose) {
                    Text("Close")
                        .font(.medium(.callout))
                        .foregroundColor(.from(.titleColor, isDarkMode))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.from(.backgroundColor, isDarkMode))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

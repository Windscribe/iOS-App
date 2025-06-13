//
//  SignupWarningView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-31.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct SignupWarningView: View {

    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @Binding var isDarkMode: Bool

    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.octagon.fill")
                .font(.regular(.largeTitle))
                .foregroundColor(.from(.iconColor, isDarkMode))

            Text(TextsAsset.NoEmailPrompt.title)
                .font(.text(.callout))
                .multilineTextAlignment(.center)
                .foregroundColor(.from(.titleColor, isDarkMode))
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text(TextsAsset.NoEmailPrompt.action)
                        .font(.text(.headline))
                        .foregroundColor(.from(.dark, isDarkMode))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.from(.titleColor, isDarkMode))
                        .clipShape(Capsule())
                }

                Button(action: onBack) {
                    Text(TextsAsset.back)
                        .font(.text(.headline))
                        .foregroundColor(.from(.titleColor, isDarkMode))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.from(.backgroundColor, isDarkMode))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 64)
        }
        .background(Color.from(.screenBackgroundColor, isDarkMode))
        .dynamicTypeSize(dynamicTypeRange)
    }
}

//
//  SignupWarningView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-31.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct SignupWarningView: View {

    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)

            Text(TextsAsset.NoEmailPrompt.title)
                .font(.text(.callout))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text(TextsAsset.NoEmailPrompt.action)
                        .font(.text(.headline))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(Capsule())
                }

                Button(action: onBack) {
                    Text(TextsAsset.back)
                        .font(.text(.headline))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 64)
        }
        .background(Color.loginRegisterBackgroundColor)
        .dynamicTypeSize(dynamicTypeRange)
    }
}

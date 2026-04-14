//
//  AuthActionButton.swift
//  Windscribe
//
//  Created by Anthony on 2026-04-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

struct AuthActionButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .authButtonEnabledText))
                } else {
                    Text(title)
                        .font(.bold(.body))
                        .foregroundColor(isEnabled ? .authButtonEnabledText : .authButtonDisabledText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                isEnabled
                    ? AnyShapeStyle(LinearGradient(colors: [.authButtonGradientStart, .authButtonGradientEnd], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color.authButtonDisabledBackground)
            )
            .clipShape(Capsule())
        }
        .disabled(!isEnabled || isLoading)
    }
}

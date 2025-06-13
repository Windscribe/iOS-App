//
//  AuthenticationSliderView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-06-09.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct AuthenticationSliderView: View {
    @Binding var isDarkMode: Bool

    var thumbSize: CGFloat = 48
    var trackHeight: CGFloat = 36
    var trackColor: Color
    var thumbColor: Color
    var arrowImage: Image
    var hintText: String

    var body: some View {
        ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: trackHeight / 2)
                .fill(trackColor)
                .frame(height: trackHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: 0.5)
                        .stroke(Color.from(.iconColor, isDarkMode).opacity(0.05), lineWidth: 1)
                )

            // Hint Text
            Text(hintText)
                .foregroundColor(.from(.infoColor, isDarkMode))
                .font(.regular(.footnote))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, thumbSize / 2)

            // Fixed Thumb at start
            Circle()
                .fill(thumbColor)
                .frame(width: thumbSize, height: thumbSize)
                .overlay(
                    arrowImage
                        .foregroundColor(.from(.actionBackgroundColor, isDarkMode))
                )
                .padding(.leading, 0)
        }
        .frame(height: thumbSize)
        .allowsHitTesting(false)
    }
}

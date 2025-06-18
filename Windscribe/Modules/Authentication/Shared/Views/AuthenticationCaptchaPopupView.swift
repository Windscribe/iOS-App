//
//  AuthenticationCaptchaPopupView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-15.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import UIKit
import Combine

struct CaptchaSheetContent: View {
    let background: UIImage
    let puzzlePiece: UIImage
    let topOffset: CGFloat
    let onSubmit: (CGFloat, [CGFloat], [CGFloat]) -> Void
    let onCancel: () -> Void

    @Binding var isDarkMode: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AuthenticationCaptchaPopupView(
                background: background,
                puzzlePiece: puzzlePiece,
                topOffset: topOffset,
                onSubmit: onSubmit,
                onCancel: onCancel,
                isDarkMode: $isDarkMode
            )
            .transition(.scale.combined(with: .opacity))
        }
    }
}

struct AuthenticationCaptchaPopupView: View {
    let background: UIImage
    let puzzlePiece: UIImage
    let topOffset: CGFloat  // Reference referenceHeight space
    let onSubmit: (_ finalX: CGFloat, _ trailX: [CGFloat], _ trailY: [CGFloat]) -> Void
    let onCancel: () -> Void

    @Binding var isDarkMode: Bool

    @State private var sliderOffsetX: CGFloat = 0
    @State private var sliderOffsetY: CGFloat = 0
    @State private var dragTrailX: [CGFloat] = []
    @State private var dragTrailY: [CGFloat] = []
    @State private var startDragOffsetX: CGFloat = 0
    @State private var previousTrailX: CGFloat = 0

    private let referenceWidth: CGFloat = 700
    private let referenceHeight: CGFloat = 400
    private let sliderWidth: CGFloat = 120
    private let maxSlideRange: CGFloat = 580 // referenceWidth - sliderWidth

    var body: some View {
        GeometryReader { geo in
            let maxWidth = min(geo.size.width - 32, 400)
            let aspectRatio = referenceHeight / referenceWidth
            let displayedHeight = maxWidth * aspectRatio
            let displayedSliderWidth = sliderWidth * (displayedHeight / referenceHeight)
            let actualRange = maxWidth - displayedSliderWidth
            let topOffsetScaled = topOffset * (displayedHeight / referenceHeight)

            VStack(spacing: 20) {
                Text(TextsAsset.Authentication.captchaDescription)
                    .font(.medium(.headline))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.from(.titleColor, isDarkMode))
                    .padding(.top, 12)

                ZStack(alignment: .topLeading) {
                    Image(uiImage: background)
                        .resizable()
                        .frame(width: maxWidth, height: displayedHeight)
                        .cornerRadius(8)

                    Image(uiImage: puzzlePiece)
                        .resizable()
                        .frame(width: displayedSliderWidth, height: displayedSliderWidth)
                        .offset(x: sliderOffsetX, y: topOffsetScaled + sliderOffsetY)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newOffsetX = (startDragOffsetX + value.translation.width)
                                        .clamped(to: 0...actualRange)
                                    let deltaX = newOffsetX - previousTrailX
                                    previousTrailX = newOffsetX

                                    sliderOffsetX = newOffsetX
                                    sliderOffsetY = value.translation.height

                                    dragTrailX.append(deltaX)
                                    dragTrailY.append(value.translation.height)
                                }
                                .onEnded { _ in
                                    startDragOffsetX = sliderOffsetX
                                    previousTrailX = sliderOffsetX

                                    Task {
                                        try? await Task.sleep(nanoseconds: 100_000_000) // 100 ms delay
                                        let sliderRatio = sliderOffsetX / actualRange
                                        let finalX = sliderRatio * maxSlideRange

                                        let scaledTrailX = dragTrailX.map { $0 * (maxSlideRange / actualRange) }
                                        let scaledTrailY = dragTrailY.map {
                                            $0 * (referenceHeight / displayedHeight)
                                        }
                                        onSubmit(finalX, scaledTrailX, scaledTrailY)
                                    }
                                }
                        )
                }
                .frame(width: maxWidth, height: displayedHeight)
                .padding(.bottom, 8)

                Button(TextsAsset.cancel, action: onCancel)
                    .font(.regular(.callout))
                    .foregroundColor(.from(.infoColor, isDarkMode))
                    .padding(.bottom, 4)
            }
            .padding()
            .background(Color.from(.popUpBackgroundColor, isDarkMode))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 0.5)
                    .stroke(Color.from(.iconColor, isDarkMode).opacity(0.05), lineWidth: 1)
            )
            .frame(width: maxWidth)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .padding(.horizontal, 16)
    }
}

// Clamp helper
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

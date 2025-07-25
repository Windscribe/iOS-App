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
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

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

    private let maxDisplayWidth: CGFloat = 400

    private let referenceWidth: CGFloat
    private let referenceHeight: CGFloat
    private let sliderWidth: CGFloat
    private let maxSlideRange: CGFloat

    init(
        background: UIImage,
        puzzlePiece: UIImage,
        topOffset: CGFloat,
        onSubmit: @escaping (_ finalX: CGFloat, _ trailX: [CGFloat], _ trailY: [CGFloat]) -> Void,
        onCancel: @escaping () -> Void,
        isDarkMode: Binding<Bool>) {
            self.background = background
            self.puzzlePiece = puzzlePiece
            self.topOffset = topOffset
            self.onSubmit = onSubmit
            self.onCancel = onCancel
            self._isDarkMode = isDarkMode

            referenceWidth = background.size.width
            referenceHeight = background.size.height
            sliderWidth = puzzlePiece.size.width
            maxSlideRange = referenceWidth - sliderWidth
    }

    var body: some View {
        GeometryReader { geo in
            // Check image dimension is bigger 400
            // 32 is 16 * 2 padding value
            let maxWidth = min(geo.size.width - 32, maxDisplayWidth)

            let aspectRatio = referenceHeight / referenceWidth
            let displayedHeight = maxWidth * aspectRatio
            let displayedSliderWidth = sliderWidth * (displayedHeight / referenceHeight)
            let actualRange = maxWidth - displayedSliderWidth
            let topOffsetScaled = topOffset * (displayedHeight / referenceHeight)

            VStack(spacing: 24) {
                Text(TextsAsset.Authentication.captchaDescription)
                    .font(.medium(.headline))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.from(.titleColor, isDarkMode))
                    .padding(.top, 8)

                ZStack(alignment: .topLeading) {
                    Image(uiImage: background)
                        .resizable()
                        .frame(width: maxWidth, height: displayedHeight)
                        .cornerRadius(8)
                        .overlay(
                             RoundedRectangle(cornerRadius: 8)
                                 .stroke(Color.white.opacity(0.15), lineWidth: 1)
                         )

                    Image(uiImage: puzzlePiece)
                        .resizable()
                        .frame(width: displayedSliderWidth, height: displayedSliderWidth)
                        .offset(x: sliderOffsetX, y: topOffsetScaled + sliderOffsetY)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    handleDragChanged(value, actualRange: actualRange)
                                }
                                .onEnded { _ in
                                    handleDragEnded(
                                        actualRange: actualRange,
                                        maxSlideRange: maxSlideRange,
                                        displayedHeight: displayedHeight,
                                        referenceHeight: referenceHeight
                                    )
                                }
                        )
                }
                .frame(width: maxWidth, height: displayedHeight)
                .padding(.bottom, 8)

                HStack {
                    Text(TextsAsset.Authentication.captchaSliderDescription)
                        .font(.regular(.caption1))
                        .foregroundColor(.from(.infoColor, isDarkMode))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(4)
                .background(Color.from(.popUpBackgroundColor, isDarkMode))
                .cornerRadius(100)
                .overlay(
                    RoundedRectangle(cornerRadius: 100)
                        .inset(by: -0.5)
                        .stroke(Color.from(.iconColor, isDarkMode).opacity(0.05), lineWidth: 1)
                )
                .frame(width: maxWidth, alignment: .center)

                Button(TextsAsset.cancel, action: onCancel)
                    .font(.regular(.callout))
                    .foregroundColor(.from(.infoColor, isDarkMode))
                    .padding(.bottom, 8)
            }
            .padding()
            .background(Color.from(.captchaBackgroundColor, isDarkMode))
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
        .dynamicTypeSize(dynamicTypeRange)
    }

    private func handleDragChanged(_ value: DragGesture.Value, actualRange: CGFloat) {
        let newOffsetX = (startDragOffsetX + value.translation.width)
            .clamped(to: 0...actualRange)
        let deltaX = newOffsetX - previousTrailX
        previousTrailX = newOffsetX

        sliderOffsetX = newOffsetX
        sliderOffsetY = value.translation.height

        dragTrailX.append(deltaX)

        dragTrailY.append(sliderOffsetY)
    }

    private func handleDragEnded(actualRange: CGFloat, maxSlideRange: CGFloat, displayedHeight: CGFloat, referenceHeight: CGFloat) {
        startDragOffsetX = sliderOffsetX
        previousTrailX = sliderOffsetX

        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)

            let sliderRatio = sliderOffsetX / actualRange
            let finalX = sliderRatio * maxSlideRange

            // Limit trail arrays to last 50 items due to server limitations
            let limitedTrailX = Array(dragTrailX.suffix(50))
            let limitedTrailY = Array(dragTrailY.suffix(50))

            let scaledTrailX = limitedTrailX.map { $0 * (maxSlideRange / actualRange) }
            let scaledTrailY = limitedTrailY.map {
                $0 * (referenceHeight / displayedHeight)
            }

            // Only register movement changes greater than 0.5 to reduce noise in trail data
            let filteredTrailX = scaledTrailX.filter { $0 == 0.0 || abs($0) > 0.5 }
            let filteredTrailY = scaledTrailY.filter { $0 == 0.0 || abs($0) > 0.5 }

            onSubmit(finalX, filteredTrailX, filteredTrailY)
        }
    }
}

// Clamp helper
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

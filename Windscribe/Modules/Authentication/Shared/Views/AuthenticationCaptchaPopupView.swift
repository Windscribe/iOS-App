//
//  AuthenticationCaptchaPopupView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-15.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import UIKit

struct CaptchaSheetContent: View {
    let background: UIImage
    let slider: UIImage
    let topOffset: CGFloat // Reference referenceHeight space
    let onSubmit: (CGFloat, [CGFloat], [CGFloat]) -> Void

    var body: some View {
        AuthenticationCaptchaPopupView(
            background: background,
            slider: slider,
            topOffset: topOffset,
            onSubmit: onSubmit
        )
    }
}

struct AuthenticationCaptchaPopupView: View {
    let background: UIImage
    let slider: UIImage
    let topOffset: CGFloat
    let onSubmit: (_ finalX: CGFloat, _ trailX: [CGFloat], _ trailY: [CGFloat]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var sliderOffsetX: CGFloat = 0
    @State private var sliderOffsetY: CGFloat = 0
    @State private var dragTrailX: [CGFloat] = []
    @State private var dragTrailY: [CGFloat] = []
    @State private var startDragOffsetX: CGFloat = 0
    @State private var previousTrailX: CGFloat = 0

    private let referenceWidth: CGFloat = 350
    private let referenceHeight: CGFloat = 200
    private let sliderWidth: CGFloat = 120
    private let maxSlideRange: CGFloat = 230 // referenceWidth - sliderWidth

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack {
                Spacer()
                GeometryReader { geo in
                    let horizontalPadding: CGFloat = 20
                    let maxWidth = min(geo.size.width - horizontalPadding * 2, 450)

                    let aspectRatio = referenceHeight / referenceWidth
                    let displayedHeight = maxWidth * aspectRatio
                    let displayedSliderWidth = sliderWidth * (displayedHeight / referenceHeight)
                    let actualRange = maxWidth - displayedSliderWidth

                    let topOffsetScaled = topOffset * (displayedHeight / referenceHeight)

                    VStack(spacing: 20) {
                        Text("Move the puzzle piece to solve the captcha")
                            .foregroundColor(.white)
                            .font(.headline.bold())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        ZStack(alignment: .topLeading) {
                            Image(uiImage: background)
                                .resizable()
                                .frame(width: maxWidth, height: displayedHeight)

                            Image(uiImage: slider)
                                .resizable()
                                .frame(width: displayedSliderWidth, height: displayedSliderWidth)
                                .offset(x: sliderOffsetX, y: topOffsetScaled + sliderOffsetY)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let translationX = value.translation.width
                                            let translationY = value.translation.height

                                            let newOffsetX = (startDragOffsetX + translationX).clamped(to: 0...actualRange)
                                            let newOffsetY = translationY

                                            let deltaX = newOffsetX - previousTrailX
                                            //  Calculate delta from previous
                                            previousTrailX = newOffsetX

                                            sliderOffsetX = newOffsetX
                                            sliderOffsetY = newOffsetY

                                            dragTrailX.append(deltaX)
                                            dragTrailY.append(translationY)
                                        }
                                        .onEnded { _ in
                                            startDragOffsetX = sliderOffsetX
                                            previousTrailX = sliderOffsetX
                                        }
                                )
                        }

                        Button(TextsAsset.submit) {
                            // Scale sliderOffsetX to ref space
                            let sliderRatio = sliderOffsetX / actualRange
                            let finalX = sliderRatio * maxSlideRange

                            let scaledTrailX = dragTrailX.map { $0 * (maxSlideRange / actualRange) }
                            let scaledTrailY = dragTrailY.map { $0 * (referenceHeight / displayedHeight) }

                            onSubmit(finalX, scaledTrailX, scaledTrailY)
                            dismiss()
                        }
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(8)
                    }
                    .frame(width: maxWidth)
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                Spacer()
            }

            Button(action: {
                dismiss()
            },label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(16)
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
}

// Clamp helper
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

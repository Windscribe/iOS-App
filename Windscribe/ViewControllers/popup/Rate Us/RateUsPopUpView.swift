//
//  RateUsPopUpView.swift
//  Windscribe
//
//  Created by Bushra Sagir on 22/09/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import SwiftUI
import StoreKit
import Swinject

@available(iOS 16.0, *)

struct RateUsPopupView: View {
    var viewModel: RateUsPopupModelType
    @Environment(\.requestReview) var requestReview
    var onDismiss: (() -> Void)?

    var body: some View {
        ZStack {
            Color(uiColor: UIColor.midnightWithOpacity(opacity: 0.95))
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // Background Container
                VStack {
                    Spacer()
                    Image(ImagesAsset.rateUs)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 86, height: 86)

                    Spacer()

                    Text(TextsAsset.RateUs.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Text(TextsAsset.RateUs.description)
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 55)

                    Spacer()

                    Button(action: actionButtonTapped) {
                        Text(TextsAsset.RateUs.action)
                            .font(.system(size: 16))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(uiColor: UIColor.seaGreen))
                            .foregroundColor(Color(uiColor: UIColor.midnight))
                            .cornerRadius(24)
                    }

                    Spacer()

                    Button(action: {
                        onDismiss?()
                        viewModel.setRateUsActionCompleted()
                    }) {
                        Text(TextsAsset.RateUs.maybeLater)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                    }

                    Spacer()
                    Button(action: {
                        onDismiss?()
                        viewModel.setRateUsActionCompleted()
                    }) {
                        Text(TextsAsset.RateUs.goAway)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(Color(uiColor: UIColor.midnightWithOpacity(opacity: 0.95)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            viewModel.setDate()
        }
    }

    @MainActor private func actionButtonTapped() {

        viewModel.setRateUsActionCompleted()
        if (viewModel.getNativeRateUsDisplayCount() ?? 0) < 3 {
            requestReview()
            viewModel.increaseNativeRateUsPopupDisplayCount()
        } else {
            viewModel.openAppStoreRattingView()
        }
    }
}

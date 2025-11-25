//
//  ShakeForDataResultsView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ShakeForDataResultsView: View, ResponsivePopupLayoutProvider {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @StateObject var viewModel: ShakeForDataResultsViewModelImpl
    @StateObject var router: ShakeForDataNavigationRouter

    init(viewModel: any ShakeForDataResultsViewModel, router: ShakeForDataNavigationRouter) {
        guard let model = viewModel as? ShakeForDataResultsViewModelImpl else {
            fatalError("ShakeForDataResultsView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        GeometryReader { geometry in
            let topSpacer = getTopSpacerHeight(for: geometry, deviceType: deviceType)
            let bottomPadding = getBottomPadding(for: geometry, deviceType: deviceType)

            PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
                VStack(spacing: 0) {
                    Spacer().frame(height: topSpacer)
                    // High Score Title
                    Text(viewModel.isNewHighScore ? TextsAsset.ShakeForData.newHighScore : TextsAsset.ShakeForData.notBad)
                        .font(.bold(.title1))
                        .foregroundColor(Color.from(.titleColor, viewModel.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.top, 120)

                    // Score Display
                    Text("\(viewModel.finalScore)")
                        .font(.score())
                        .foregroundColor(Color.from(.titleColor, viewModel.isDarkMode))
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Action Buttons
                    VStack(spacing: 24) {
                        // Try Again Button
                        Button {
                            router.navigate(to: .shakeGame)
                        } label: {
                            Text(TextsAsset.ShakeForData.tryAgain)
                                .font(.bold(.title3))
                                .foregroundColor(Color.from(.titleColor, viewModel.isDarkMode))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(Color.from(.titleColor, viewModel.isDarkMode), lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 44)

                        // View Leaderboard Button
                        Button {
                            router.navigate(to: .leaderboard)
                        } label: {
                            Text(TextsAsset.ShakeForData.popupViewLeaderboard)
                                .font(.bold(.title3))
                                .foregroundColor(Color.from(.infoColor, viewModel.isDarkMode))
                        }

                        Rectangle()
                            .fill(Color.from(.infoColor, viewModel.isDarkMode))
                            .frame(height: 1)
                            .padding(.horizontal, 32)

                        // Leave Button
                        Button {
                            router.dismiss()
                        } label: {
                            Text(TextsAsset.ShakeForData.leave)
                                .font(.bold(.title3))
                                .foregroundColor(Color.from(.infoColor, viewModel.isDarkMode))
                        }
                        .padding(.bottom, 32)
                        Spacer()
                    }
                    .padding(.bottom, bottomPadding)
                    .padding(.top, 80)
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(routeLink)
        .dynamicTypeSize(dynamicTypeRange)
        .withRouter(router)
    }

    @ViewBuilder
    private var routeLink: some View {
        NavigationLink(
            destination: routeDestination,
            isActive: Binding(
                get: { router.activeRoute != nil },
                set: { newValue in
                    if !newValue {
                        router.pop()
                    }
                }
            )
        ) {
            EmptyView()
        }
        .hidden()
    }

    @ViewBuilder
    private var routeDestination: some View {
        if let route = router.activeRoute {
            router.createView(for: route)
        } else {
            EmptyView()
        }
    }
}

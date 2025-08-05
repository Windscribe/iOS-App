//
//  ShakeForDataGameView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 18/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ShakeForDataGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: ShakeForDataGameViewModelImpl
    @StateObject var router: ShakeForDataNavigationRouter

    init(viewModel: any ShakeForDataGameViewModel, router: ShakeForDataNavigationRouter) {
        guard let model = viewModel as? ShakeForDataGameViewModelImpl else {
            fatalError("ShakeForDataMainView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        ZStack {
            // Background that extends over navigation bar
            viewModel.backgroundColor
                .animation(.easeInOut(duration: 0.5), value: viewModel.backgroundColor)
                .ignoresSafeArea(.all, edges: .all)

            VStack {
                // Timer at top
                HStack {
                    Image(ImagesAsset.ShakeForData.arrowTopLeft)
                        .resizable()
                        .frame(width: 60, height: 60)

                    Spacer()

                    VStack {
                        Image(systemName: "timer")
                            .foregroundColor(.white)

                        Text("\(viewModel.timeRemaining)")
                            .font(.bold(.title1))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Image(ImagesAsset.ShakeForData.arrowTopRight)
                        .resizable()
                        .frame(width: 60, height: 60)
                }
                .padding(24)

                    Spacer()
                // Shake counter in center
                VStack(spacing: 16) {
                    Text("\(viewModel.shakeCount)")
                        .font(.system(size: 120, weight: .bold, design: .default))
                        .foregroundColor(.white)

                    Text(TextsAsset.ShakeForData.shakes)
                        .font(.bold(.title3))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity,
                       alignment: .init(horizontal: .center, vertical: .center))

                    Spacer()
                HStack {
                    Image(ImagesAsset.ShakeForData.arrowBottomLeft)
                        .resizable()
                        .frame(width: 60, height: 60)

                    Button {
                        viewModel.quitGame()
                    } label: {
                        HStack {
                            Text(TextsAsset.ShakeForData.quit)
                                .font(.bold(.callout))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    Image(ImagesAsset.ShakeForData.arrowBottomRight)
                        .resizable()
                        .frame(width: 60, height: 60)
                }
                .padding(24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.startGame()
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onChange(of: viewModel.shouldNavigateToResults) { shouldNavigate in
            if shouldNavigate {
                router.navigate(to: .results)
            }
        }
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

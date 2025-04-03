//
//  WelcomeView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {

    @Environment(\.deviceType) private var deviceType

    @StateObject private var viewModel: WelcomeViewModelImpl
    @StateObject private var router = LoginNavigationRouter()

    @State private var shouldNavigateToSignup = false

    private let dynamicTypeRange = (...DynamicTypeSize.large)

    init(viewModel: any WelcomeViewModel) {
        guard let model = viewModel as? WelcomeViewModelImpl else {
            fatalError("WelcomeView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
            contentView
                .getPresentingController { controller in
                    guard let presentingController = controller else { return }
                    viewModel.setPresentingController(presentingController)
                }
                .onReceive(viewModel.routeToSignup) { success in
                    if success {
                        router.navigate(to: .signup)
                        shouldNavigateToSignup = true
                    }
                }
                .onReceive(viewModel.routeToMainView) { _ in
                    viewModel.navigateToMain()
                }
                .fullScreenCover(isPresented: Binding(
                     get: { router.activeRoute == .emergency },
                     set: { if !$0 { router.pop() } }
                 )) {
                     router.createView(for: .emergency)
                 }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .withRouter(router)
    }

    @ViewBuilder
    private var contentView: some View {
        GeometryReader { geometry in
            if deviceType == .iPadLandscape {
                HStack {
                    featureContentView(geometry: geometry)
                        .padding(.horizontal, geometry.size.width * 0.065)

                    authenticationButtonView()
                        .padding(.horizontal, geometry.size.width * 0.065)
                }
                .background {
                    Color(UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0))
                        .ignoresSafeArea()

                    Image(viewModel.backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            } else {
                VStack {
                    featureContentView(geometry: geometry)

                    authenticationButtonView()
                        .padding(.bottom, 24)
                        .padding(.horizontal, 24)
                }
                .padding(.horizontal, (deviceType == .iPadPortrait) ? geometry.size.width * 0.25 : 0)
                .padding(.vertical, (deviceType == .iPadPortrait) ? geometry.size.width * 0.1 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    Color(UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0))
                        .ignoresSafeArea()

                    Image(viewModel.backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            }
        }
    }

    @ViewBuilder
    private func featureContentView(geometry: GeometryProxy) -> some View {
        if deviceType == .iPadLandscape {
            VStack(alignment: .center) {
                Image(viewModel.iconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .padding(.bottom, 80)

                tabInfoView(geometry: geometry)

                PageIndicator(currentPage: viewModel.scrollOrder)
                    .padding(.top, 8)
            }
            .frame(maxHeight: .infinity)
        } else {
            VStack {
                Image(viewModel.iconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)

                VStack {
                    tabInfoView(geometry: geometry)
                        .padding(.horizontal, 24)

                    PageIndicator(currentPage: viewModel.scrollOrder)
                        .padding(.top, 8)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func tabInfoView(geometry: GeometryProxy) -> some View {
        TabView(selection: $viewModel.scrollOrder) {
            ForEach(0..<viewModel.tabInfoImages.count, id: \.self) { index in
                WelcomeInfoPageView(
                    imageName: viewModel.tabInfoImages[index],
                    text: viewModel.tabInfoTexts[index]
                )
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(maxHeight: geometry.size.height * 0.3)
        .onReceive(Timer.publish(every: 4, on: .main, in: .common).autoconnect()) { _ in
            withAnimation {
                viewModel.slideScrollView()
            }
        }
    }
}

extension WelcomeView {

    @ViewBuilder
    private func authenticationButtonView() -> some View {
        VStack(spacing: 12) {
            // Google Authentication
            Button(action: {
                router.navigate(to: .login)
            }, label: {
                HStack(alignment: .center, spacing: 10) {
                    Image(viewModel.signupGoogleImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    Text(TextsAsset.Welcome.continueWithGoogle)
                        .font(.medium(.body))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.black.opacity(0.54))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .clipShape(Capsule())
            })

            // Apple Authentication
            Button(action: {
                router.navigate(to: .login)
            }, label: {
                HStack(alignment: .center, spacing: 10) {
                    Image(viewModel.signupAppleImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    Text(TextsAsset.Welcome.continueWithApple)
                        .font(.medium(.body))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
            })

            // Emergency & Sign-Up/Login Section
            HStack {
                // Emergency Connect
                Button(action: {
                    router.navigate(to: .emergency)
                }) {
                    if viewModel.emergencyConnectStatus {
                        Text(viewModel.emergencyConnectOnText)
                            .font(.semiBold(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .foregroundColor(Color.welcomeEmergencyButtonColor)
                    } else {
                        Text(viewModel.connectionFaultText)
                            .font(.semiBold(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .foregroundColor(Color.welcomeButtonTextColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    // SignUp Button
                    ZStack {
                        Button(action: {
                            viewModel.continueButtonTapped()
                        }, label: {
                            ZStack {
                                Text(viewModel.signupText)
                                    .font(.semiBold(.callout))
                                    .dynamicTypeSize(dynamicTypeRange)
                                    .foregroundColor(Color.welcomeButtonTextColor)
                                    .opacity(viewModel.showLoadingView ? 0 : 1)

                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding()
                                    .opacity(viewModel.showLoadingView ? 1 : 0)
                            }
                        })
                        .disabled(viewModel.showLoadingView)

                        // Navigation trigger (invisible)
                        NavigationLink(
                            destination: router.createView(for: .signup),
                            isActive: $shouldNavigateToSignup
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    }

                    // Seperators
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: 14)

                    // Login Button
                    NavigationLink(
                        destination: router.createView(for: .login),
                        isActive: Binding(
                            get: { router.activeRoute == .login },
                            set: { if !$0 { router.pop() } }
                        )
                    ) {
                        Button(action: {
                            router.navigate(to: .login)
                        }, label: {
                            Text(viewModel.loginText)
                                .font(.semiBold(.callout))
                                .dynamicTypeSize(dynamicTypeRange)
                                .foregroundColor(.welcomeButtonTextColor)
                        })
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 8)
        }
    }
}

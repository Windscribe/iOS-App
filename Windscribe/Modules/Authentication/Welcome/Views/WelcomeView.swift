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
    @Environment(\.dynamicTypeDefaultRange) private var dynamicTypeRange

    @StateObject private var viewModel: WelcomeViewModelImpl
    @StateObject private var router: AuthenticationNavigationRouter
    @State private var showSSOErrorAlert = false
    @State private var errorMessage = ""

    init(viewModel: any WelcomeViewModel, router: AuthenticationNavigationRouter) {
        guard let model = viewModel as? WelcomeViewModelImpl else {
            fatalError("WelcomeView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
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
                        router.shouldNavigateToSignup = true
                    }
                }
                .onReceive(viewModel.routeToMainView) { _ in
                    router.routeToMainView()
                }
                .onReceive(viewModel.$failedState.compactMap { $0 }) { message in
                    self.showSSOErrorAlert = true
                    self.errorMessage = message
                }
                .alert(isPresented: $showSSOErrorAlert) {
                    Alert(title: Text(TextsAsset.Welcome.ssoErrorAppleTitle),
                          message: Text(errorMessage),
                          dismissButton:
                            .default(Text(TextsAsset.ok)) {
                                showSSOErrorAlert = false
                                errorMessage = ""
                          }
                    )
                }
                .fullScreenCover(
                    isPresented: $router.shouldNavigateToEmergency,
                    content: {
                        router.createView(for: .emergency)
                    }
                )

        }
        .navigationViewStyle(StackNavigationViewStyle())
        .dynamicTypeSize(dynamicTypeRange)
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
                .padding(.horizontal, (deviceType == .iPadPortrait) ? geometry.size.width * 0.2 : 0)
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
                    .padding(.top, 10)

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
                    .padding(.top, 10)

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
            // Apple Authentication
            Button(action: {
                viewModel.continueWithAppleTapped()
            }, label: {
                HStack(alignment: .center, spacing: 10) {
                    Image(viewModel.signupAppleImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    Text(TextsAsset.Welcome.continueWithApple)
                        .font(.medium(.body))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
            })

            // Login Button
            NavigationLink(
                destination: router.createView(for: .login),
                isActive: $router.shouldNavigateToLogin
            ) {
                Button(action: {
                    router.shouldNavigateToLogin = true
                }, label: {
                    Text(viewModel.loginText)
                        .font(.medium(.body))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                })
            }

            // Emergency & Sign-Up/Login Section
            HStack {
                // Emergency Connect
                Button(action: {
                    router.shouldNavigateToEmergency = true
                }, label: {
                    if viewModel.emergencyConnectStatus {
                        Text(viewModel.emergencyConnectOnText)
                            .font(.semiBold(.callout))
                            .foregroundColor(Color.welcomeEmergencyButtonColor)
                    } else {
                        Text(viewModel.connectionFaultText)
                            .font(.semiBold(.callout))
                            .foregroundColor(Color.welcomeButtonTextColor)
                    }
                })
                .frame(maxWidth: .infinity, alignment: .leading)

                // SignUp Button
                ZStack {
                    Button(action: {
                        router.shouldNavigateToSignup = true
                    }, label: {
                        ZStack {
                            Text(viewModel.signupText)
                                .font(.semiBold(.callout))
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
                        destination: router.createView(for: .signup(claimGhostAccount: false)),
                        isActive: $router.shouldNavigateToSignup
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 8)
        }
    }
}

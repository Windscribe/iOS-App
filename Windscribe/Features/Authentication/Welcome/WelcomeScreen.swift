//
//  WelcomeScreen.swift
//  Windscribe
//
//  Created by Andre Fonseca on 10/06/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

/// Top-level navigation destination. Reads `@Environment`, constructs the
/// view model, hands it to the inner `AboutView`. See "Routing" in
/// `docs/PROJECT_NEO.md` for the Screen/View/Route convention.
@available(iOS 17.0, *)
struct WelcomeScreen: View {
    @Environment(\.userDataProviding) private var userDataProviding
    @Environment(\.preferencesReading) private var preferencesReading
    @Environment(\.preferencesWriting) private var preferencesWriting
    @Environment(\.vpnConnecting) private var vpnConnecting
    @Environment(\.ssoManaging) private var ssoManaging
    @Environment(\.logger) private var logger

    var body: some View {
        WelcomeContentView(viewModel: WelcomeScreenViewModel(userDataProviding: userDataProviding,
                                                             preferencesReading: preferencesReading,
                                                             preferencesWriting: preferencesWriting,
                                                             vpnConnecting: vpnConnecting,
                                                             ssoManaging: ssoManaging,
                                                             logger: logger))
    }
}

@available(iOS 17.0, *)
private struct WelcomeContentView: View {
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange
    @Environment(\.deviceType) private var deviceType

    @State private var viewModel: WelcomeScreenViewModel
    @State private var route: AuthenticationRouteID?

    init(viewModel: WelcomeScreenViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindable = viewModel
        NavigationView {
            ZStack {
                contentView
                .fullScreenCover(isPresented: $bindable.isEmergencyConnectPresented) {
                    EmergencyConnectScreen()
                }

                NavigationLink(
                    destination: destinationView(),
                    isActive: $bindable.isNavigating,
                    label: { EmptyView() }
                )
                .hidden()
                .disabled(viewModel.showLoadingView)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .dynamicTypeSize(dynamicTypeRange)

    }

    @ViewBuilder
    private func destinationView() -> some View {
        if let route = viewModel.navigationRoute {
            switch route {
            case .login:
                LoginScreen()
            case .signup(let claimGhostAccount):
                SignUpScreen(claimGhostAccount: claimGhostAccount)
            default:
                EmptyView()
            }
        } else {
            EmptyView()
        }
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

                    Image(ImagesAsset.Welcome.background)
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

                    Image(ImagesAsset.Welcome.background)
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
                Image(ImagesAsset.Welcome.icon)
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
                Image(ImagesAsset.Welcome.icon)
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

@available(iOS 17.0, *)
extension WelcomeContentView {

    @ViewBuilder
    private func authenticationButtonView() -> some View {
        VStack(spacing: 12) {
            // Apple Authentication
            Button(action: {
                viewModel.continueWithAppleTapped()
            }, label: {
                ZStack {
                    if viewModel.showLoadingView {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        HStack(alignment: .center, spacing: 10) {
                            Image(ImagesAsset.Welcome.appleIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)

                            Text(TextsAsset.Welcome.continueWithApple)
                                .font(.medium(.body))
                                .foregroundColor(.black)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
            })
            .disabled(viewModel.showLoadingView)

            Button(action: {
                viewModel.navigate(to: .login)
            }, label: {
                Text(TextsAsset.Welcome.login)
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
            .disabled(viewModel.showLoadingView)
            .opacity(viewModel.showLoadingView ? 0.5 : 1.0)

            // Emergency & Sign-Up/Login Section
            HStack {
                // Emergency Connect
                Button(action: {
                    viewModel.navigate(to: .emergency)
                }, label: {
                    if viewModel.emergencyConnectStatus {
                        Text(TextsAsset.Welcome.emergencyConnectOn)
                            .font(.semiBold(.callout))
                            .foregroundColor(Color.welcomeEmergencyButtonColor)
                    } else {
                        Text(TextsAsset.Welcome.connectionFault)
                            .font(.semiBold(.callout))
                            .foregroundColor(Color.welcomeButtonTextColor)
                    }
                })
                .disabled(viewModel.showLoadingView)
                .opacity(viewModel.showLoadingView ? 0.5 : 1.0)
                .frame(maxWidth: .infinity, alignment: .leading)

                // SignUp Button
                ZStack {
                    Button(action: {
                        viewModel.navigate(to: .signup(claimGhostAccount: false))
                    }, label: {
                        Text(TextsAsset.Welcome.signup)
                            .font(.semiBold(.callout))
                            .foregroundColor(Color.welcomeButtonTextColor)
                    })
                    .disabled(viewModel.showLoadingView)
                    .opacity(viewModel.showLoadingView ? 0.5 : 1.0)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 8)
        }
    }
}

//
//  WelcomeView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {

    @StateObject private var viewModel: WelcomeViewModel

    init(viewModel: WelcomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Background
            Color(UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0))
                .ignoresSafeArea()

            Image(viewModel.backgroundImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                // Logo
                VStack {
                    Image(viewModel.iconImage)
                        .resizable()
                        .frame(width: 54, height: 54)
                        .padding(.top, 48)
                }

                Spacer()

                // Info Pages
                TabView(selection: $viewModel.scrollOrder) {
                    ForEach(0..<viewModel.tabInfoImages.count, id: \.self) { index in
                        InfoPageView(
                            imageName: viewModel.tabInfoImages[index],
                            text: viewModel.tabInfoTexts[index]
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 300)
                .onReceive(Timer.publish(every: 2, on: .main, in: .common).autoconnect()) { _ in
                    withAnimation {
                        viewModel.slideScrollView()
                    }
                }

                PageIndicator(currentPage: viewModel.scrollOrder)
                    .padding(.top, 8)

                Spacer()

                // Buttons
                VStack(spacing: 22) {
                    Button(action: viewModel.continueButtonTapped) {
                        if viewModel.showLoadingView {
                            ProgressView()
                        } else {
                            Text(viewModel.getStartedText)
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(23)
                        }
                    }
                    .frame(height: 48)

                    Button(action: {
                        viewModel.routeToLogin.send(())
                    }, label: {
                        Text(viewModel.loginText)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(23)
                    })
                    .frame(height: 48)

                    Button(action: {
                        viewModel.routeToEmergency.send(())
                    }, label: {
                        Text(viewModel.connectionFaultText)
                            .font(.footnote)
                            .foregroundColor(.white)
                            .opacity(0.5)
                    })
                    .padding(.top, 8)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 45)
                    }
                }
            }
            .padding([.trailing, .leading], 32)
        }
        .getPresentingController { controller in
            guard let presentingController = controller else { return }

            viewModel.setPresentingController(presentingController)
        }
        .onReceive(viewModel.routeToSignup) { _ in
            viewModel.navigateToSignUp()
        }
        .onReceive(viewModel.routeToMainView) { _ in
            viewModel.navigateToMain()
        }
        .onReceive(viewModel.routeToLogin) { _ in
            viewModel.navigateToLogin()
        }
        .onReceive(viewModel.routeToEmergency) { _ in
            viewModel.navigateToEmergency()
        }
    }
}

// MARK: - Info Page with Image and Text

struct InfoPageView: View {
    let imageName: String
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)

            Text(text)
                .font(.text(.title1))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Custom Page Indicator

struct PageIndicator: View {
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

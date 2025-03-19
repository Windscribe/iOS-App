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

    private let dynamicTypeRange = (...DynamicTypeSize.large)

    init(viewModel: WelcomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Image(viewModel.iconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)

                VStack {
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
                    .frame(maxHeight: geometry.size.height * 0.3)
                    .onReceive(Timer.publish(every: 4, on: .main, in: .common).autoconnect()) { _ in
                        withAnimation {
                            viewModel.slideScrollView()
                        }
                    }

                    PageIndicator(currentPage: viewModel.scrollOrder)
                        .padding(.top, 8)
                }
                .frame(maxHeight: .infinity)

                VStack(spacing: 12) {
                    Button(action: viewModel.continueButtonTapped) {
                        if viewModel.showLoadingView {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                        } else {
                            Text(viewModel.getStartedText)
                                .font(.semiBold(.body))
                                .dynamicTypeSize(dynamicTypeRange)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    }

                    Button(action: {
                        viewModel.routeToLogin.send(())
                    }, label: {
                        Text(viewModel.loginText)
                            .font(.semiBold(.body))
                            .dynamicTypeSize(dynamicTypeRange)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    })
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                    Button(action: {
                        viewModel.routeToEmergency.send(())
                    }, label: {
                        Text(viewModel.connectionFaultText)
                            .font(.medium(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .foregroundColor(.white)
                            .opacity(0.5)
                    })
                    .padding(.vertical, 4)
                }
                .padding([.horizontal, .bottom], 24)
            }
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

    private let dynamicTypeRange = (...DynamicTypeSize.large)

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200, maxHeight: 300)

            Text(text)
                .font(.text(.title1))
                .dynamicTypeSize(dynamicTypeRange)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
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

#Preview {
    PageIndicator(currentPage: 2)
}

#Preview {
    TabView(selection: .constant(1)) {
        ForEach(0..<4, id: \.self) { index in
            InfoPageView(imageName: "welcome-info-tab-1", text: "Lorem ipsum dolor sit amet")
            .tag(index)
        }
    }
    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    .frame(height: 300)
}

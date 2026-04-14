//
//  SignUpView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-27.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Combine

struct SignUpView: View {

    enum Field: Hashable {
        case username, password, confirmPassword, email, voucher, referral
    }

    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @EnvironmentObject var signupFlowContext: SignupFlowContext
    @ObservedObject private var keyboard = KeyboardResponder()

    @StateObject private var viewModel: SignUpViewModelImpl
    @StateObject private var router: AuthenticationNavigationRouter

    @State private var showEmailWarning = false
    @State private var navigateToLogin = false

    @FocusState private var focusedField: Field?
    @State private var fieldPositions: [String: Anchor<CGRect>] = [:]

    private var isLastFieldFocused: Bool {
        if viewModel.isReferralVisible {
            return focusedField == .referral
        } else if viewModel.isVoucherVisible {
            return focusedField == .voucher
        } else {
            return focusedField == .email
        }
    }

    init(viewModel: any SignUpViewModel, router: AuthenticationNavigationRouter) {
        guard let model = viewModel as? SignUpViewModelImpl else {
            fatalError("SignUpView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
                    ScrollView {
                        tabContent
                            .padding()
                            .padding(.bottom, keyboard.currentHeight)
                            .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
                            .background(attachPreferenceReader())
                            .frame(minHeight: geometry.size.height)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear.frame(height: keyboard.currentHeight == 0 ? 0 : 60)
                    }
                    .onChange(of: viewModel.email) { _ in
                        if viewModel.isEmailValid(viewModel.email) {
                            viewModel.failedState = .none
                        }
                    }
                    .onChange(of: viewModel.selectedTab) { _ in
                        viewModel.failedState = .none
                    }
                    .onChange(of: focusedField) { field in
                        if field != nil {
                            viewModel.failedState = .none
                        }

                        guard let field = field else { return }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            scrollToField(field, proxy: proxy, geometry: geometry)
                        }
                    }
                    .onTapGesture {
                        focusedField = nil
                    }
                    .onReceive(viewModel.routeTo) { route in
                        switch route {
                        case .main:
                            router.routeToMainView()
                        case .confirmEmail:
                            showEmailWarning = true
                        }
                    }
                    .onReceive(viewModel.showRestrictiveNetworkModal) { shouldShow in
                        router.shouldNavigateToRestrictiveNetwork = shouldShow
                    }
                }
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .navigationTitle(signupFlowContext.isFromGhostAccount ? TextsAsset.accountSetupTitle : TextsAsset.Welcome.signup)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.showLoadingView && !viewModel.showCaptchaPopup)
        .toolbar {
            signupToolbar()
        }
        .background(
            NavigationLink(
                destination: router.createView(for: .login),
                isActive: $navigateToLogin
            ) { EmptyView() }
                .hidden()
        )
        .fullScreenCover(isPresented: $showEmailWarning) {
            SignupWarningView(
                isDarkMode: $viewModel.isDarkMode,
                onContinue: {
                    showEmailWarning = false
                    viewModel.continueButtonTapped(ignoreEmailCheck: true, claimAccount: false)
                },
                onBack: {
                    showEmailWarning = false
                }
            )
        }
        .sheet(isPresented: $router.shouldNavigateToRestrictiveNetwork) {
            router.createView(for: .restrictiveNetwork)
        }
        .overlay(
            ZStack {
                // Loading overlay
                if viewModel.showLoadingView && !viewModel.showCaptchaPopup {
                    Color.from(.dark, viewModel.isDarkMode)
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .allowsHitTesting(true)
                        .zIndex(0)
                }

                if viewModel.showCaptchaPopup, let data = viewModel.captchaData {
                    Color.from(.dark, viewModel.isDarkMode)
                        .opacity(0.65)
                        .ignoresSafeArea()
                        .zIndex(1)

                    CaptchaSheetContent(
                        background: data.background,
                        puzzlePiece: data.slider,
                        topOffset: CGFloat(data.top),
                        onSubmit: { xOffset, trailX, trailY in
                            viewModel.submitCaptcha(
                                captchaSolution: xOffset,
                                trailX: trailX,
                                trailY: trailY
                            )
                        },
                        onCancel: {
                            viewModel.showCaptchaPopup = false
                        },
                        isDarkMode: $viewModel.isDarkMode
                    )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(2)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.showCaptchaPopup)
        )
        .disabled(viewModel.showLoadingView && !viewModel.showCaptchaPopup)
        .interactiveDismissDisabled(viewModel.showLoadingView && !viewModel.showCaptchaPopup)
    }
}

// MARK: - Helpers

private extension SignUpView {
    func attachPreferenceReader() -> some View {
        GeometryReader { _ in
            Color.clear
                .onPreferenceChange(ViewFrameKey.self) { prefs in
                    self.fieldPositions = prefs
                }
        }
    }
}

// MARK: - Tab Content

private extension SignUpView {

    @ViewBuilder
    var tabContent: some View {
        switch viewModel.selectedTab {
        case .standard:
            StandardSignUpContentView(
                viewModel: viewModel,
                focusedField: $focusedField,
                onSignUp: {
                    focusedField = nil
                    viewModel.continueButtonTapped(ignoreEmailCheck: false, claimAccount: false)
                },
                onLogin: {
                    navigateToLogin = true
                },
                onDismiss: {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        case .hashed:
            HashedSignUpContentView(viewModel: viewModel)
        }
    }
}

// MARK: - Toolbar

private extension SignUpView {

    @ToolbarContentBuilder
    func signupToolbar() -> some ToolbarContent {
        AuthTabPickerToolbarItem(
            selectedTab: $viewModel.selectedTab,
            isDarkMode: $viewModel.isDarkMode,
            isVisible: !signupFlowContext.isFromGhostAccount
        )
        ToolbarItemGroup(placement: .keyboard) {
            Button(action: {
                moveFocus(up: true)
            },label: {
                Image(systemName: "chevron.up")
            })
            .disabled(focusedField == .username)

            Button(action: {
                moveFocus(up: false)
            },label: {
                Image(ImagesAsset.chevronDown)
            })
            .disabled(isLastFieldFocused)

            Spacer()

            Button(TextsAsset.Authentication.done) {
                focusedField = nil
            }
        }
    }
}

// MARK: - Focus & Scroll

extension SignUpView {

    private func moveFocus(up: Bool) {
        guard let current = focusedField else { return }

        // Determine active fields based on visibility
        let allFields: [Field] = {
            var fields: [Field] = [.username, .password, .confirmPassword, .email]
            if viewModel.isVoucherVisible {
                fields.append(.voucher)
            }
            if viewModel.isReferralVisible {
                fields.append(.referral)
            }
            return fields
        }()

        guard let currentIndex = allFields.firstIndex(of: current) else { return }

        let nextIndex = up
            ? max(currentIndex - 1, 0)
            : min(currentIndex + 1, allFields.count - 1)

        focusedField = allFields[nextIndex]
    }

    private func scrollToField(_ field: Field, proxy: ScrollViewProxy, geometry: GeometryProxy) {
        let anchorId = "\(field)-anchor"

        guard let anchor = fieldPositions[anchorId] else { return }

        let fieldRect = geometry[anchor]
        let fieldBottomY = fieldRect.maxY

        let screenHeight = geometry.size.height
        let keyboardHeight = keyboard.currentHeight
        let buffer: CGFloat = 16

        let visibleBottomY = screenHeight - keyboardHeight - buffer

        if fieldBottomY > visibleBottomY {
            withAnimation {
                proxy.scrollTo(field, anchor: .top)
            }
        }
    }
}

final class SignupFlowContext: ObservableObject {
    @Published var isFromGhostAccount = false
}

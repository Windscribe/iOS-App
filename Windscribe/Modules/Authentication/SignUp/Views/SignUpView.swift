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
        case username, password, email, voucher, referral
    }

    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @EnvironmentObject var signupFlowContext: SignupFlowContext
    @ObservedObject private var keyboard = KeyboardResponder()

    @StateObject private var viewModel: SignUpViewModelImpl
    @StateObject private var router: AuthenticationNavigationRouter

    @State private var showEmailWarning = false

    @FocusState private var focusedField: Field?
    @State private var fieldPositions: [String: Anchor<CGRect>] = [:]

    private var isUsernameError: Bool {
        if case .username = viewModel.failedState {
            return true
        }
        if case .api = viewModel.failedState {
            return true
        }

        return false
    }

    private var usernameErrorMessage: String? {
        if case .username(let msg) = viewModel.failedState {
            return msg
        }
        if case .api(let msg) = viewModel.failedState {
            return msg
        }

        return nil
    }

    private var showUsernameIcon: Bool { isUsernameError }

    private var isPasswordError: Bool {
        if case .password = viewModel.failedState {
            return true
        }
        if case .api = viewModel.failedState {
            return true
        }

        return false
    }

    private var passwordErrorMessage: String? {
        if case .password(let msg) = viewModel.failedState {
            return msg
        }
        if case .api(let msg) = viewModel.failedState {
            return msg
        }

        return nil
    }

    private var showPasswordIcon: Bool { isPasswordError }

    private var isEmailError: Bool {
        if case .email = viewModel.failedState {
            return true
        }
        if case .api = viewModel.failedState {
            return true
        }

        return false
    }

    private var emailErrorMessage: String? {
        if case .email(let msg) = viewModel.failedState {
            return msg
        }
        if case .api(let msg) = viewModel.failedState {
            return msg
        }
        return nil
    }

    private var showEmailIcon: Bool {
        isEmailError
    }

    private var apiOrNetworkError: String? {
        switch viewModel.failedState {
        case .api(let msg):
            return msg
        case .network(let msg):
            return msg
        default:
            return nil
        }
    }

    private var isLastFieldFocused: Bool {
        if viewModel.isReferralVisible {
            return focusedField == .referral
        } else {
            return focusedField == .voucher
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
                        VStack(spacing: 20) {
                            usernameField
                            passwordField
                            emailField
                            voucherField
                            referralToggle
                            referralSection
                            apiOrNetworkErrorLabel
                            continueButton
                            setupLaterButton
                        }
                        .padding()
                        .padding(.bottom, keyboard.currentHeight) // Dynamic keyboard-aware padding
                        .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
                        .background(attachPreferenceReader())
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear.frame(height: keyboard.currentHeight == 0 ? 0 : 60)
                    }
                    .onChange(of: viewModel.email) { _ in
                        if viewModel.isEmailValid(viewModel.email) {
                            viewModel.failedState = .none
                        }
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
                }
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .navigationTitle(signupFlowContext.isFromGhostAccount ? TextsAsset.accountSetupTitle : TextsAsset.Welcome.signup)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            signupToolbar()
        }
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
        .overlay(
            ZStack {
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
    }
}

private extension SignUpView {

    @ViewBuilder
    var usernameField: some View {
        LoginTextField(
            title: TextsAsset.chooseUsername,
            placeholder: TextsAsset.Authentication.enterUsername,
            showError: isUsernameError,
            errorMessage: usernameErrorMessage,
            showWarningIcon: showUsernameIcon,
            text: $viewModel.username,
            isDarkMode: $viewModel.isDarkMode
        )
        .focused($focusedField, equals: .username)
        .id(Field.username)
        .readingFrame(id: "username-anchor")
    }

    @ViewBuilder
    var passwordField: some View {
        LoginTextField(
            title: TextsAsset.choosePassword,
            placeholder: TextsAsset.Authentication.enterPassword,
            isSecure: true,
            showError: isPasswordError,
            errorMessage: passwordErrorMessage,
            showWarningIcon: showPasswordIcon,
            text: $viewModel.password,
            isDarkMode: $viewModel.isDarkMode
        )
        .focused($focusedField, equals: .password)
        .id(Field.password)
        .readingFrame(id: "password-anchor")
    }

    @ViewBuilder
    var emailField: some View {
        VStack(spacing: 6) {
            LoginTextField(
                title: "\(TextsAsset.email) (\(TextsAsset.optional))",
                placeholder: TextsAsset.Authentication.enterEmailAddress,
                showError: isEmailError,
                errorMessage: emailErrorMessage,
                showWarningIcon: showEmailIcon,
                text: $viewModel.email,
                isDarkMode: $viewModel.isDarkMode,
                keyboardType: .emailAddress,
                trailingView: AnyView(
                    Text(TextsAsset.get10GbAMonth)
                        .font(.medium(.callout))
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                )
            )
            .focused($focusedField, equals: .email)
            .id(Field.email)
            .readingFrame(id: "email-anchor")

            Text(TextsAsset.emailInfoLabel)
                .font(.regular(.footnote))
                .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    var voucherField: some View {
        LoginTextField(
            title: "\(TextsAsset.voucherCode) (\(TextsAsset.optional))",
            placeholder: TextsAsset.Authentication.enterVoucherCode,
            text: $viewModel.voucherCode,
            isDarkMode: $viewModel.isDarkMode
        )
        .focused($focusedField, equals: .voucher)
        .id(Field.voucher)
        .readingFrame(id: "voucher-anchor")
    }

    @ViewBuilder
    var referralToggle: some View {
        if !signupFlowContext.isFromGhostAccount {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.referralViewTapped()
                }
            }, label: {
                HStack(spacing: 8) {
                    Text(TextsAsset.referredBySomeone)
                        .font(.medium(.callout))
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(viewModel.isReferralVisible ? 180 : 0))
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                        .animation(.easeInOut(duration: 0.25), value: viewModel.isReferralVisible)
                }
            })
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    var referralSection: some View {
        if viewModel.isReferralVisible {
            VStack(alignment: .leading, spacing: 12) {
                ForEach([
                    TextsAsset.youWillBothGetTenGb,
                    TextsAsset.ifYouGoPro
                ], id: \.self) { text in
                    HStack(alignment: .top, spacing: 6) {
                        Text("✓")
                            .foregroundColor(.loginRegisterEnabledButtonColor)
                            .font(.regular(.callout))
                        Text(text)
                            .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                            .font(.regular(.callout))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                LoginTextField(
                    title: "",
                    placeholder: viewModel.isEmailValid(viewModel.email)
                        ? TextsAsset.referringUsername
                        : TextsAsset.pleaseEnterEmailFirst,
                    showError: viewModel.isReferralVisible && !viewModel.isEmailValid(viewModel.email),
                    errorMessage: viewModel.isReferralVisible && !viewModel.isEmailValid(viewModel.email)
                        ? TextsAsset.pleaseEnterEmailFirst
                        : nil,
                    showWarningIcon: viewModel.isReferralVisible && !viewModel.isEmailValid(viewModel.email),
                    text: $viewModel.referralUsername,
                    isDarkMode: $viewModel.isDarkMode
                )
                .disabled(!viewModel.isEmailValid(viewModel.email))
                .focused($focusedField, equals: .referral)
                .id(Field.referral)
                .readingFrame(id: "referral-anchor")

                Text(TextsAsset.mustConfirmEmail)
                    .font(.regular(.footnote))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isReferralVisible)
        }
    }

    @ViewBuilder
    var apiOrNetworkErrorLabel: some View {
        if let errorText = apiOrNetworkError {
            Text(errorText)
                .font(.regular(.footnote))
                .foregroundColor(.loginRegisterFailedField)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    var continueButton: some View {
        Button {
            focusedField = nil
            viewModel.continueButtonTapped(ignoreEmailCheck: false, claimAccount: false)
        } label: {
            ZStack {
                if viewModel.showLoadingView {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text(TextsAsset.continue)
                        .font(.bold(.body))
                        .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .background(viewModel.isContinueButtonEnabled
                        ? Color.loginRegisterEnabledButtonColor
                        : .from(.iconColor, viewModel.isDarkMode))
            .clipShape(Capsule())
        }
        .disabled(!viewModel.isContinueButtonEnabled || viewModel.showLoadingView)
    }

    @ViewBuilder
    var setupLaterButton: some View {
        if signupFlowContext.isFromGhostAccount {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text(TextsAsset.setupLater)
                    .foregroundColor(.welcomeButtonTextColor)
                    .font(.bold(.title3))
                    .padding(.top, 12)
            })
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

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

private extension SignUpView {

    @ToolbarContentBuilder
    func signupToolbar() -> some ToolbarContent {
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
                Image(systemName: "chevron.down")
            })
            .disabled(isLastFieldFocused)

            Spacer()

            Button(TextsAsset.Authentication.done) {
                focusedField = nil
            }
        }
    }
}

extension SignUpView {

    private func moveFocus(up: Bool) {
        guard let current = focusedField else { return }

        // Determine active fields based on referral visibility
        let allFields: [Field] = {
            var fields: [Field] = [.username, .password, .email, .voucher]
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

        let screenHeight = UIScreen.main.bounds.height
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

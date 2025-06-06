//
//  LoginView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-21.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct LoginView: View {

    enum Field {
        case username, password, twoFactorCode
    }

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @ObservedObject private var keyboard = KeyboardResponder()
    @FocusState private var focusedField: Field?
    @State private var fieldPositions: [String: Anchor<CGRect>] = [:]

    @StateObject private var viewModel: LoginViewModelImpl
    @StateObject private var router: AuthenticationNavigationRouter
    @State private var safariURL: URL?

    //  Error Flags
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
        if case .api = viewModel.failedState {
            return true
        }

        return false
    }

    private var passwordErrorMessage: String? {
        if case .api(let msg) = viewModel.failedState {
            return msg
        }

        return nil
    }

    private var showPasswordIcon: Bool {
        isPasswordError
    }

    private var isTwoFaError: Bool {
        if case .twoFactor = viewModel.failedState {
            return true
        }

        return false
    }

    private var showTwoFaIcon: Bool { isTwoFaError }

    init(viewModel: any LoginViewModel, router: AuthenticationNavigationRouter) {
        guard let model = viewModel as? LoginViewModelImpl else {
            fatalError("LoginView must be initialized properly")
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
                            usernameField()
                            passwordField()
                            twoFactorView()
                            twoFaAndForgotFooter()
                            errorDisplayView()
                            continueButton()
                        }
                        .padding()
                        .padding(.bottom, keyboard.currentHeight + 16)
                        .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
                        .background(attachPreferenceReader())
                    }
                    .onChange(of: focusedField) { field in
                        guard let field = field else { return }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            scrollToField(field, proxy: proxy, geometry: geometry)
                        }

                        viewModel.failedState = nil
                    }
                    .onTapGesture {
                        focusedField = nil
                    }
                    .onReceive(viewModel.routeToMainView) { _ in
                        router.routeToMainView()
                    }
                }
            }
            .navigationTitle(TextsAsset.Welcome.login)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { loginToolbar() }
            .sheet(item: $safariURL) { url in
                SafariView(url: url)
            }
            .fullScreenCover(isPresented: $viewModel.showCaptchaPopup) {
                if let data = viewModel.captchaData {
                    CaptchaSheetContent(
                        background: data.background,
                        slider: data.slider,
                        topOffset: CGFloat(data.top),
                        onSubmit: { xOffset, trailX, trailY in
                            viewModel.submitCaptcha(captchaSolution: xOffset, trailX: trailX, trailY: trailY)
                        },
                        isDarkMode: $viewModel.isDarkMode
                    )
                }
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
    }
}

private extension LoginView {
    @ViewBuilder
    func usernameField() -> some View {
        LoginTextField(
            title: TextsAsset.Authentication.username,
            placeholder: TextsAsset.Authentication.enterUsername,
            showError: isUsernameError,
            errorMessage: usernameErrorMessage,
            showWarningIcon: showUsernameIcon,
            showFieldErrorText: false,
            text: $viewModel.username,
            isDarkMode: $viewModel.isDarkMode
        )
        .focused($focusedField, equals: .username)
        .id(Field.username)
        .readingFrame(id: "username-anchor")
    }

    @ViewBuilder
    func passwordField() -> some View {
        LoginTextField(
            title: TextsAsset.Authentication.password,
            placeholder: TextsAsset.Authentication.enterPassword,
            isSecure: true,
            showError: isPasswordError,
            errorMessage: passwordErrorMessage,
            showWarningIcon: showPasswordIcon,
            showFieldErrorText: false,
            text: $viewModel.password,
            isDarkMode: $viewModel.isDarkMode
        )
        .focused($focusedField, equals: .password)
        .id(Field.password)
        .readingFrame(id: "password-anchor")
    }

    @ViewBuilder
    func twoFactorView() -> some View {
        if viewModel.show2FAField {
            VStack(alignment: .leading, spacing: 8) {
                LoginTextField(
                    title: TextsAsset.Authentication.twoFactorCode,
                    placeholder: "",
                    showError: isTwoFaError,
                    showWarningIcon: showTwoFaIcon,
                    showFieldErrorText: false,
                    text: $viewModel.twoFactorCode,
                    isDarkMode: $viewModel.isDarkMode,
                    titleTapAction: {
                        withAnimation {
                            viewModel.twoFactorCode = ""
                            viewModel.show2FAField = false
                        }
                    },
                    keyboardType: .numberPad
                )
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .twoFactorCode)
                .id(Field.twoFactorCode)
                .readingFrame(id: "twoFactorCode-anchor")

                Text(TextsAsset.Authentication.twoFactorDescription)
                    .font(.regular(.footnote))
                    .foregroundColor(.from(.titleColor, viewModel.isDarkMode).opacity(0.5))
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.show2FAField)
        }
    }

    @ViewBuilder
    func twoFaAndForgotFooter() -> some View {
        HStack {
            if !viewModel.show2FAField {
                Button(TextsAsset.Authentication.twoFactorCode) {
                    withAnimation {
                        viewModel.show2FAField.toggle()
                        if !viewModel.show2FAField {
                            viewModel.twoFactorCode = ""
                        }
                    }
                }
                .foregroundColor(.from(.titleColor, viewModel.isDarkMode).opacity(0.5))
                .font(.medium(.callout))
            }

            Spacer()

            Button(TextsAsset.Authentication.forgotPassword) {
                safariURL = URL(string: Links.forgotPassword)
            }
            .foregroundColor(.from(.titleColor, viewModel.isDarkMode).opacity(0.5))
            .font(.medium(.callout))
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: viewModel.show2FAField)
    }

    @ViewBuilder
    func errorDisplayView() -> some View {
        if let error = viewModel.failedState {
            Text(errorMessage(for: error))
                .foregroundColor(.loginRegisterFailedField)
                .font(.regular(.footnote))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    func continueButton() -> some View {
        Button {
            focusedField = nil
            viewModel.continueButtonTapped()
        } label: {
            ZStack {
                if viewModel.showLoadingView {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text(TextsAsset.continue)
                        .font(.bold(.body))
                        .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isContinueButtonEnabled
                        ? Color.loginRegisterEnabledButtonColor
                        : .from(.iconColor, viewModel.isDarkMode))
            .clipShape(Capsule())
        }
        .disabled(!viewModel.isContinueButtonEnabled || viewModel.showLoadingView)
    }
}

private extension LoginView {
    func attachPreferenceReader() -> some View {
        GeometryReader { _ in
            Color.clear
                .onPreferenceChange(ViewFrameKey.self) { prefs in
                    self.fieldPositions = prefs
                }
        }
    }
}

private extension LoginView {
    @ToolbarContentBuilder
    func loginToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Button(action: {
                moveFocus(up: true)
            }, label: {
                Image(systemName: "chevron.up")
            })
            .disabled(focusedField == .username)

            Button(action: {
                moveFocus(up: false)
            }, label: {
                Image(systemName: "chevron.down")
            })
            .disabled(focusedField == .twoFactorCode || (!viewModel.show2FAField && focusedField == .password))

            Spacer()

            Button(TextsAsset.Authentication.done) {
                focusedField = nil
            }
        }
    }
}

private extension LoginView {
    /// Error Mapping
    /// - Parameter state: for error state
    /// - Returns: return what needs to be shown on screen
    private func errorMessage(for state: LoginErrorState) -> String {
        switch state {
        case .username(let error): return error
        case .network(let error): return error
        case .twoFactor(let error): return error
        case .api(let error): return error
        case .loginCode(let error): return error
        }
    }

    private func moveFocus(up: Bool) {
        guard let current = focusedField else { return }
        let allFields: [Field] = viewModel.show2FAField
            ? [.username, .password, .twoFactorCode]
            : [.username, .password]

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
        let keyboardToolbarHeight: CGFloat = 44
        let buffer: CGFloat = 16

        let visibleBottomY = screenHeight - keyboardHeight - keyboardToolbarHeight - buffer

        if fieldBottomY > visibleBottomY {
            withAnimation {
                proxy.scrollTo(field, anchor: .top)
            }
        }
    }
}

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
        case username, password, twoFactorCode, accountHash
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
        return false
    }

    private var usernameErrorMessage: String? {
        if case .username(let msg) = viewModel.failedState {
            return msg
        }
        return nil
    }

    private var showUsernameIcon: Bool { isUsernameError }

    private var isPasswordError: Bool {
        false
    }

    private var passwordErrorMessage: String? {
        nil
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

    private var isHashError: Bool {
        if case .api = viewModel.failedState {
            return true
        }
        return false
    }

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
                        tabContent
                            .padding()
                            .padding(.bottom, keyboard.currentHeight + 16)
                            .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
                            .background(attachPreferenceReader())
                    }
                    .onChange(of: viewModel.selectedTab) { _ in
                        viewModel.failedState = nil
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
                    .onReceive(viewModel.showRestrictiveNetworkModal) { shouldShow in
                        router.shouldNavigateToRestrictiveNetwork = shouldShow
                    }
                }
            }
            .navigationTitle(TextsAsset.Welcome.login)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(viewModel.showLoadingView && !viewModel.showCaptchaPopup)
            .toolbar { loginToolbar() }
            .sheet(item: $safariURL) { url in
                SafariView(url: url, isDarkMode: viewModel.isDarkMode)
            }
            .fileImporter(
                isPresented: $viewModel.showFileImporter,
                allowedContentTypes: [.data, .item],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        viewModel.loadHashFromFile(data)
                    }
                }
            }
            .fullScreenCover(
                isPresented: $router.shouldNavigateToRestrictiveNetwork,
                content: {
                    router.createView(for: .restrictiveNetwork)
                }
            )
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
        .dynamicTypeSize(dynamicTypeRange)
    }
}

// MARK: - Tab Content

private extension LoginView {

    @ViewBuilder
    var tabContent: some View {
        switch viewModel.selectedTab {
        case .standard:
            standardContent
        case .hashed:
            hashedContent
        }
    }

    var standardContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            usernameField
            passwordField
            twoFactorToggle
            twoFactorField
            errorDisplayView
            continueButton
        }
    }

    var hashedContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            hashField
            twoFactorToggle
            twoFactorField
            errorDisplayView
            continueButton
        }
    }
}

// MARK: - Standard Fields

private extension LoginView {

    @ViewBuilder
    var usernameField: some View {
        LoginTextField(
            title: TextsAsset.Authentication.username,
            placeholder: TextsAsset.Authentication.enterUsername,
            showError: isUsernameError,
            errorMessage: usernameErrorMessage,
            showWarningIcon: showUsernameIcon,
            showFieldErrorText: false,
            text: $viewModel.username,
            isDarkMode: $viewModel.isDarkMode,
            textContentType: .username
        )
        .focused($focusedField, equals: .username)
        .id(Field.username)
        .readingFrame(id: "username-anchor")
    }

    @ViewBuilder
    var passwordField: some View {
        LoginTextField(
            title: TextsAsset.Authentication.password,
            secondaryTitle: TextsAsset.Authentication.forgotPassword,
            placeholder: TextsAsset.Authentication.enterPassword,
            isSecure: true,
            showError: isPasswordError,
            errorMessage: passwordErrorMessage,
            showWarningIcon: showPasswordIcon,
            showFieldErrorText: false,
            text: $viewModel.password,
            isDarkMode: $viewModel.isDarkMode,
            titleTapAction: {
                safariURL = URL(string: Links.forgotPassword)
            },
            textContentType: .password
        )
        .focused($focusedField, equals: .password)
        .id(Field.password)
        .readingFrame(id: "password-anchor")
    }

    @ViewBuilder
    var twoFactorToggle: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.show2FAField.toggle()
                if !viewModel.show2FAField {
                    viewModel.twoFactorCode = ""
                }
            }
        }) {
            HStack {
                Text(TextsAsset.addTwoFA)
                    .font(.medium(.callout))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                Spacer()

                OptionalPill(isDarkMode: $viewModel.isDarkMode)

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .rotationEffect(.degrees(viewModel.show2FAField ? 180 : 0))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.show2FAField)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var twoFactorField: some View {
        if viewModel.show2FAField {
            LoginTextField(
                title: "",
                placeholder: TextsAsset.enterTwoFACode,
                showError: isTwoFaError,
                showFieldErrorText: false,
                text: $viewModel.twoFactorCode,
                isDarkMode: $viewModel.isDarkMode,
                keyboardType: .default,
                textContentType: .oneTimeCode,
                trailingView: AnyView(
                    InfoAlertButton(
                        title: TextsAsset.addTwoFA,
                        message: TextsAsset.twoFADescription,
                        isDarkMode: $viewModel.isDarkMode
                    )
                )
            )
            .focused($focusedField, equals: .twoFactorCode)
            .id(Field.twoFactorCode)
            .readingFrame(id: "twoFactorCode-anchor")
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.show2FAField)
        }
    }
}

// MARK: - Hashed Fields

private extension LoginView {

    @ViewBuilder
    var hashField: some View {
        LoginTextField(
            title: TextsAsset.accountHash,
            placeholder: TextsAsset.enterAccountHashOrUpload,
            showError: isHashError,
            showFieldErrorText: false,
            text: $viewModel.accountHash,
            isDarkMode: $viewModel.isDarkMode,
            trailingView: AnyView(
                Button(action: {
                    viewModel.showFileImporter = true
                }) {
                    Image(ImagesAsset.arrowUpload)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                }
                .buttonStyle(.plain)
            )
        )
        .focused($focusedField, equals: .accountHash)
        .id(Field.accountHash)
        .readingFrame(id: "accountHash-anchor")
    }
}

// MARK: - Shared

private extension LoginView {

    @ViewBuilder
    var errorDisplayView: some View {
        if let error = viewModel.failedState {
            Text(error.displayMessage)
                .foregroundColor(.loginRegisterFailedField)
                .font(.regular(.footnote))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    var continueButton: some View {
        AuthActionButton(
            title: TextsAsset.login,
            isEnabled: viewModel.isContinueButtonEnabled,
            isLoading: viewModel.showLoadingView
        ) {
            focusedField = nil
            viewModel.continueButtonTapped()
        }
    }
}

// MARK: - Helpers

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

// MARK: - Toolbar

private extension LoginView {
    @ToolbarContentBuilder
    func loginToolbar() -> some ToolbarContent {
        AuthTabPickerToolbarItem(
            selectedTab: $viewModel.selectedTab,
            isDarkMode: $viewModel.isDarkMode
        )
        ToolbarItemGroup(placement: .keyboard) {
            Button(action: {
                moveFocus(up: true)
            }, label: {
                Image(systemName: "chevron.up")
            })
            .disabled(focusedField == .username || focusedField == .accountHash)

            Button(action: {
                moveFocus(up: false)
            }, label: {
                Image(ImagesAsset.chevronDown)
            })
            .disabled((!viewModel.show2FAField && focusedField == .accountHash)
                      || (!viewModel.show2FAField && focusedField == .password)
                      || (viewModel.show2FAField && focusedField == .twoFactorCode))

            Spacer()

            Button(TextsAsset.Authentication.done) {
                focusedField = nil
            }
        }
    }
}

// MARK: - Focus & Scroll

private extension LoginView {
    func moveFocus(up: Bool) {
        guard let current = focusedField else { return }

        let allFields: [Field] = {
            switch viewModel.selectedTab {
            case .standard:
                var fields: [Field] = [.username, .password]
                if viewModel.show2FAField { fields.append(.twoFactorCode) }
                return fields
            case .hashed:
                var fields: [Field] = [.accountHash]
                if viewModel.show2FAField { fields.append(.twoFactorCode) }
                return fields
            }
        }()

        guard let currentIndex = allFields.firstIndex(of: current) else { return }

        let nextIndex = up
            ? max(currentIndex - 1, 0)
            : min(currentIndex + 1, allFields.count - 1)

        focusedField = allFields[nextIndex]
    }

    func scrollToField(_ field: Field, proxy: ScrollViewProxy, geometry: GeometryProxy) {
        let anchorId = "\(field)-anchor"

        guard let anchor = fieldPositions[anchorId] else { return }

        let fieldRect = geometry[anchor]
        let fieldBottomY = fieldRect.maxY

        let screenHeight = geometry.size.height
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

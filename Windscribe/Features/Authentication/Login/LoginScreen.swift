//
//  LoginScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

/// Top-level navigation destination for the Neo Login screen.
@available(iOS 17.0, *)
struct LoginScreen: View {
    @Environment(\.loginAuthenticating) private var loginAuthenticating
    @Environment(\.userDataProviding) private var userDataProviding
    @Environment(\.emergencyConnecting) private var emergencyConnecting
    @Environment(\.protocolManaging) private var protocolManaging
    @Environment(\.connectivityObserving) private var connectivityObserving
    @Environment(\.logger) private var logger
    @Environment(\.mainRouting) private var mainRouting

    var body: some View {
        LoginContentView(
            viewModel: LoginScreenViewModel(
                loginAuthenticating: loginAuthenticating,
                userDataProviding: userDataProviding,
                emergencyConnecting: emergencyConnecting,
                protocolManaging: protocolManaging,
                connectivityObserving: connectivityObserving,
                logger: logger,
                mainRouting: mainRouting
            )
        )
    }
}

@available(iOS 17.0, *)
private struct LoginContentView: View {
    enum Field {
        case username, password, twoFactorCode, accountHash
    }

    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange
    @Environment(\.lookAndFeel) private var lookAndFeel

    @FocusState private var focusedField: Field?
    @State private var fieldPositions: [String: Anchor<CGRect>] = [:]
    @State private var viewModel: LoginScreenViewModel
    @State private var safariURL: URL?

    init(viewModel: LoginScreenViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var isUsernameError: Bool {
        if case .username = viewModel.failedState { return true }
        return false
    }

    private var usernameErrorMessage: String? {
        if case .username(let msg) = viewModel.failedState { return msg }
        return nil
    }

    private var isTwoFaError: Bool {
        if case .twoFactor = viewModel.failedState { return true }
        return false
    }

    private var isHashError: Bool {
        if case .api = viewModel.failedState { return true }
        return false
    }

    var body: some View {
        @Bindable var bindable = viewModel

        ScrollViewReader { proxy in
            GeometryReader { geometry in
                ZStack {
                    BaseContentView() {
                        ScrollView {
                            tabContent
                                .padding()
                                .padding(.bottom, 16)
                                .background(attachPreferenceReader())
                        }
                        .onChange(of: viewModel.selectedTab) { _, _ in
                            viewModel.clearError()
                        }
                        .onChange(of: focusedField) { _, field in
                            guard let field = field else { return }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                scrollToField(field, proxy: proxy, geometry: geometry)
                            }

                            viewModel.clearError()
                        }
                        .onTapGesture {
                            focusedField = nil
                        }
                    }

                    NavigationLink(
                        destination: RestrictiveNetworkScreen(),
                        isActive: $bindable.showRestrictiveNetworkModal,
                        label: { EmptyView() }
                    )
                    .hidden()
                    .disabled(viewModel.showLoadingView)
                }
            }
            .navigationTitle(TextsAsset.Welcome.login)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(viewModel.showLoadingView && !viewModel.showCaptchaPopup)
            .toolbar { loginToolbar() }
            .sheet(item: $safariURL) { url in
                SafariView(url: url)
            }
            .fileImporter(
                isPresented: $bindable.showFileImporter,
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
            .overlay(loadingAndCaptchaOverlay)
            .disabled(viewModel.showLoadingView && !viewModel.showCaptchaPopup)
            .interactiveDismissDisabled(viewModel.showLoadingView && !viewModel.showCaptchaPopup)
            .task {
                await viewModel.startObservers()
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
    }

    @ViewBuilder
    private var loadingAndCaptchaOverlay: some View {
        ZStack {
            if viewModel.showLoadingView && !viewModel.showCaptchaPopup {
                Color.from(.dark, lookAndFeel.isDarkMode)
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                    .zIndex(0)
            }

            if viewModel.showCaptchaPopup, let data = viewModel.captchaData {
                Color.from(.dark, lookAndFeel.isDarkMode)
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
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showCaptchaPopup)
    }
}

// MARK: - Tab Content

@available(iOS 17.0, *)
private extension LoginContentView {
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

// MARK: - Fields

@available(iOS 17.0, *)
private extension LoginContentView {
    @ViewBuilder
    var usernameField: some View {
        LoginTextField(
            title: TextsAsset.Authentication.username,
            placeholder: TextsAsset.Authentication.enterUsername,
            showError: isUsernameError,
            errorMessage: usernameErrorMessage,
            showWarningIcon: isUsernameError,
            showFieldErrorText: false,
            text: binding(\.username),
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
            showError: false,
            errorMessage: nil,
            showWarningIcon: false,
            showFieldErrorText: false,
            text: binding(\.password),
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
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))

                Spacer()

                OptionalPill()

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .rotationEffect(.degrees(viewModel.show2FAField ? 180 : 0))
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
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
                text: binding(\.twoFactorCode),
                keyboardType: .default,
                textContentType: .oneTimeCode,
                trailingView: AnyView(
                    InfoAlertButton(
                        title: TextsAsset.addTwoFA,
                        message: TextsAsset.twoFADescription
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

    @ViewBuilder
    var hashField: some View {
        LoginTextField(
            title: TextsAsset.accountHash,
            placeholder: TextsAsset.enterAccountHashOrUpload,
            showError: isHashError,
            showFieldErrorText: false,
            text: binding(\.accountHash),
            trailingView: AnyView(
                Button(action: {
                    viewModel.showFileImporter = true
                }) {
                    Image(ImagesAsset.arrowUpload)
                        .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
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

@available(iOS 17.0, *)
private extension LoginContentView {
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

    func binding<Value>(_ keyPath: ReferenceWritableKeyPath<LoginScreenViewModel, Value>) -> Binding<Value> {
        Binding(
            get: { viewModel[keyPath: keyPath] },
            set: { viewModel[keyPath: keyPath] = $0 }
        )
    }

    func attachPreferenceReader() -> some View {
        GeometryReader { _ in
            Color.clear
                .onPreferenceChange(ViewFrameKey.self) { prefs in
                    fieldPositions = prefs
                }
        }
    }
}

// MARK: - Toolbar

@available(iOS 17.0, *)
private extension LoginContentView {
    @ToolbarContentBuilder
    func loginToolbar() -> some ToolbarContent {
        AuthTabPickerToolbarItem(
            selectedTab: binding(\.selectedTab)
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

@available(iOS 17.0, *)
private extension LoginContentView {
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
        let keyboardToolbarHeight: CGFloat = 44
        let buffer: CGFloat = 16
        let visibleBottomY = screenHeight - keyboardToolbarHeight - buffer

        if fieldBottomY > visibleBottomY {
            withAnimation {
                proxy.scrollTo(field, anchor: .top)
            }
        }
    }
}

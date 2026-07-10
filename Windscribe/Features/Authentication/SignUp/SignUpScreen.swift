//
//  SignUpScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

/// Top-level navigation destination for the Neo Signup screen.
@available(iOS 17.0, *)
struct SignUpScreen: View {
    let claimGhostAccount: Bool

    @Environment(\.signUpAuthenticating) private var signUpAuthenticating
    @Environment(\.userDataProviding) private var userDataProviding
    @Environment(\.emergencyConnecting) private var emergencyConnecting
    @Environment(\.protocolManaging) private var protocolManaging
    @Environment(\.connectivityObserving) private var connectivityObserving
    @Environment(\.logger) private var logger
    @Environment(\.mainRouting) private var mainRouting

    var body: some View {
        SignUpContentView(
            viewModel: SignUpScreenViewModel(
                claimGhostAccount: claimGhostAccount,
                signUpAuthenticating: signUpAuthenticating,
                userDataProviding: userDataProviding,
                emergencyConnecting: emergencyConnecting,
                protocolManaging: protocolManaging,
                connectivityObserving: connectivityObserving,
                logger: logger,
                mainRouting: mainRouting
            ),
            claimGhostAccount: claimGhostAccount
        )
    }
}

@available(iOS 17.0, *)
private struct SignUpContentView: View {
    enum Field: Hashable {
        case username, password, confirmPassword, email, voucher, referral
    }

    private static let defaultHashFileName = "windscribe-auth.key"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange
    @Environment(\.mainRouting) private var mainRouting
    @Environment(\.lookAndFeel) private var lookAndFeel

    @FocusState private var focusedField: Field?
    @State private var fieldPositions: [String: Anchor<CGRect>] = [:]
    @State private var viewModel: SignUpScreenViewModel
    @State private var navigateToLogin = false
    @State private var safariURL: URL?
    @State private var fileError: String?
    @State private var isShowingCopiedFeedback = false
    @State private var copyFeedbackResetTask: DispatchWorkItem?
    let claimGhostAccount: Bool

    init(viewModel: SignUpScreenViewModel, claimGhostAccount: Bool) {
        _viewModel = State(initialValue: viewModel)
        self.claimGhostAccount = claimGhostAccount
    }

    private var isLastFieldFocused: Bool {
        if viewModel.isReferralVisible {
            return focusedField == .referral
        } else if viewModel.isVoucherVisible {
            return focusedField == .voucher
        }
        return focusedField == .email
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
                                .background(attachPreferenceReader())
                                .frame(minHeight: geometry.size.height)
                        }
                        .onChange(of: viewModel.email) { _, _ in
                            if viewModel.isEmailValid(viewModel.email) {
                                viewModel.failedState = .none
                            }
                        }
                        .onChange(of: viewModel.selectedTab) { _, _ in
                            viewModel.failedState = .none
                        }
                        .onChange(of: focusedField) { _, field in
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
        }
        .dynamicTypeSize(dynamicTypeRange)
        .navigationTitle(claimGhostAccount ? TextsAsset.accountSetupTitle : TextsAsset.Welcome.signup)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.showLoadingView && !viewModel.showCaptchaPopup)
        .toolbar { signupToolbar() }
        .background(
            NavigationLink(destination: LoginScreen(), isActive: $navigateToLogin) { EmptyView() }
                .hidden()
        )
        .fullScreenCover(isPresented: $bindable.showEmailWarning) {
            SignupWarningView(
                onContinue: {
                    viewModel.showEmailWarning = false
                    viewModel.continueButtonTapped(ignoreEmailCheck: true)
                },
                onBack: {
                    viewModel.showEmailWarning = false
                }
            )
        }
        .sheet(isPresented: $bindable.showRestrictiveNetworkModal) {
            mainRouting.restrictiveNetworkView()
        }
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
        }
        .fileExporter(
            isPresented: $bindable.showFileExporter,
            document: MultiFormatDocument(
                documentInfo: DocumentFormatInfo(
                    fileData: viewModel.preImageData,
                    type: .data,
                    tempFileName: Self.defaultHashFileName
                )
            ),
            contentType: .data,
            defaultFilename: Self.defaultHashFileName
        ) { result in
            if case .failure(let error) = result {
                fileError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $bindable.showFileImporter,
            allowedContentTypes: [.data, .item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                guard url.startAccessingSecurityScopedResource() else {
                    fileError = "Unable to access the selected file."
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let data = try Data(contentsOf: url)
                    viewModel.loadHashFromFile(data)
                } catch {
                    fileError = error.localizedDescription
                }
            case .failure(let error):
                fileError = error.localizedDescription
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { fileError != nil },
            set: { if !$0 { fileError = nil } }
        )) {
            Alert(title: Text("Error"), message: Text(fileError ?? ""))
        }
        .overlay(loadingAndCaptchaOverlay)
        .disabled(viewModel.showLoadingView && !viewModel.showCaptchaPopup)
        .interactiveDismissDisabled(viewModel.showLoadingView && !viewModel.showCaptchaPopup)
        .task {
            await viewModel.startObservers()
        }
        .onChange(of: viewModel.accountHash) { _, _ in
            hideCopiedFeedback()
        }
        .onDisappear {
            copyFeedbackResetTask?.cancel()
            copyFeedbackResetTask = nil
        }
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
                        viewModel.submitCaptcha(captchaSolution: xOffset, trailX: trailX, trailY: trailY)
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
private extension SignUpContentView {
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
                .padding(.bottom, -20)
            confirmPasswordField
            emailField
            voucherToggle
                .padding(.bottom, viewModel.isVoucherVisible ? -20 : 0)
            voucherSection
            referralToggle
                .padding(.bottom, viewModel.isReferralVisible ? -20 : 0)
            referralSection
            apiOrNetworkErrorLabel
            signUpButton(ignoreEmailCheck: false)
                .padding(.top, viewModel.isReferralVisible ? 0 : 20)
            setupLaterButton
            Spacer()
            loginLink
        }
    }

    var hashedContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            hashExplanationSection
            hashDisplay
            hashActionButtons
            voucherToggle
            voucherSection
            backupCheckbox
            apiOrNetworkErrorLabel
            signUpButton(ignoreEmailCheck: true)
            Spacer()
        }
    }
}

// MARK: - Standard fields

@available(iOS 17.0, *)
private extension SignUpContentView {
    var usernameField: some View {
        LoginTextField(
            title: TextsAsset.chooseUsername,
            placeholder: TextsAsset.Authentication.enterUsername,
            showError: isUsernameError,
            errorMessage: usernameErrorMessage,
            showWarningIcon: isUsernameError,
            text: binding(\.username),
            trailingView: AnyView(
                Button(action: { viewModel.generateUsername() }) {
                    Image(ImagesAsset.arrowRefresh)
                        .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
                }
                .buttonStyle(.plain)
            )
        )
        .focused($focusedField, equals: .username)
        .id(Field.username)
        .readingFrame(id: "username-anchor")
    }

    var passwordField: some View {
        LoginTextField(
            title: TextsAsset.choosePassword,
            placeholder: TextsAsset.Authentication.enterPassword,
            isSecure: true,
            showError: isPasswordError,
            errorMessage: passwordErrorMessage,
            showWarningIcon: isPasswordError,
            text: binding(\.password),
            trailingView: AnyView(
                Button(action: { viewModel.generatePassword() }) {
                    Image(ImagesAsset.arrowRefresh)
                        .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
                }
                .buttonStyle(.plain)
            )
        )
        .focused($focusedField, equals: .password)
        .id(Field.password)
        .readingFrame(id: "password-anchor")
    }

    var confirmPasswordField: some View {
        LoginTextField(
            title: "",
            placeholder: TextsAsset.confirmPassword,
            isSecure: true,
            showPasswordToggle: false,
            showError: isConfirmPasswordError,
            errorMessage: confirmPasswordErrorMessage,
            showWarningIcon: isConfirmPasswordError,
            text: binding(\.confirmPassword)
        )
        .focused($focusedField, equals: .confirmPassword)
        .id(Field.confirmPassword)
        .readingFrame(id: "confirmPassword-anchor")
    }

    var emailField: some View {
        VStack(spacing: 6) {
            HStack {
                Text(TextsAsset.addEmail)
                    .font(.medium(.callout))
                    .foregroundColor(isEmailError ? .loginRegisterFailedField : .from(.titleColor, lookAndFeel.isDarkMode))

                Spacer()

                OptionalPill()
            }

            LoginTextField(
                title: "",
                placeholder: TextsAsset.Authentication.enterEmailAddress,
                showError: isEmailError,
                errorMessage: emailErrorMessage,
                showWarningIcon: false,
                text: binding(\.email),
                keyboardType: .emailAddress,
                trailingView: AnyView(
                    InfoAlertButton(
                        title: TextsAsset.addEmail,
                        message: TextsAsset.emailInfoLabel
                    )
                )
            )
        }
        .focused($focusedField, equals: .email)
        .id(Field.email)
        .readingFrame(id: "email-anchor")
    }

    @ViewBuilder
    var referralToggle: some View {
        if !claimGhostAccount {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) { viewModel.referralViewTapped() }
            }) {
                HStack {
                    Text(TextsAsset.referredBySomeone)
                        .font(.medium(.callout))
                        .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))
                    Spacer()
                    OptionalPill()
                    Image(ImagesAsset.chevronDown)
                        .font(.caption)
                        .rotationEffect(.degrees(viewModel.isReferralVisible ? 180 : 0))
                        .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
                        .animation(.easeInOut(duration: 0.25), value: viewModel.isReferralVisible)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    var referralSection: some View {
        if viewModel.isReferralVisible {
            VStack(alignment: .leading, spacing: 12) {
                ForEach([TextsAsset.youWillBothGetTenGb, TextsAsset.ifYouGoPro], id: \.self) { text in
                    HStack(alignment: .top, spacing: 6) {
                        Text("\u{2713}")
                            .foregroundColor(.loginRegisterEnabledButtonColor)
                            .font(.regular(.callout))
                        Text(text)
                            .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
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
                    text: binding(\.referralUsername)
                )
                .disabled(!viewModel.isEmailValid(viewModel.email))
                .focused($focusedField, equals: .referral)
                .id(Field.referral)
                .readingFrame(id: "referral-anchor")

                Text(TextsAsset.mustConfirmEmail)
                    .font(.regular(.footnote))
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isReferralVisible)
        }
    }
}

// MARK: - Hashed fields

@available(iOS 17.0, *)
private extension SignUpContentView {
    var hashExplanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(TextsAsset.hashedTabExplanation)
                .font(.regular(.callout))
                .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { safariURL = URL(string: Links.learnMoreHashedLogin) }) {
                Text(TextsAsset.learnMore)
                    .font(.regular(.callout))
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.7))
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }

    var hashDisplay: some View {
        ZStack {
            Text(viewModel.accountHash.formattedHash(splitAt: 18))
                .font(.system(.body, design: .monospaced))
                .bold()
                .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                .opacity(isShowingCopiedFeedback ? 0 : 1)

            if isShowingCopiedFeedback {
                Text(TextsAsset.copied)
                    .font(.system(.body, design: .monospaced))
                    .bold()
                    .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                    .transition(.opacity)
            }
        }
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
        )
    }

    var hashActionButtons: some View {
        HStack(spacing: 16) {
            hashActionButton(imageName: ImagesAsset.arrowRefresh) { viewModel.regenerateHash() }
            hashActionButton(imageName: ImagesAsset.arrowUpload) { viewModel.showFileImporter = true }
            hashActionButton(imageName: ImagesAsset.arrowDownload) { viewModel.showFileExporter = true }
            hashActionButton(imageName: ImagesAsset.copyClipboard) {
                viewModel.copyHash()
                showCopiedFeedback()
            }
        }
        .frame(maxWidth: .infinity)
    }

    func hashActionButton(imageName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(imageName)
                .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))
                .frame(width: 80, height: 48)
                .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    var backupCheckbox: some View {
        Button(action: { viewModel.hasBackedUpHash.toggle() }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: viewModel.hasBackedUpHash ? "checkmark.square.fill" : "square")
                    .foregroundColor(viewModel.hasBackedUpHash
                        ? .loginRegisterEnabledButtonColor
                        : .from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
                    .font(.title3)

                Text(TextsAsset.hashedBackupConfirmation)
                    .font(.regular(.callout))
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared pieces

@available(iOS 17.0, *)
private extension SignUpContentView {
    var voucherToggle: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) { viewModel.voucherViewTapped() }
        }) {
            HStack {
                Text(TextsAsset.gotVoucherCode)
                    .font(.medium(.callout))
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))
                Spacer()
                OptionalPill()
                Image(ImagesAsset.chevronDown)
                    .font(.caption)
                    .rotationEffect(.degrees(viewModel.isVoucherVisible ? 180 : 0))
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isVoucherVisible)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var voucherSection: some View {
        if viewModel.isVoucherVisible {
            LoginTextField(
                title: "",
                placeholder: TextsAsset.Authentication.enterVoucherCode,
                text: binding(\.voucherCode)
            )
            .focused($focusedField, equals: .voucher)
            .id(Field.voucher)
            .readingFrame(id: "voucher-anchor")
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isVoucherVisible)
        }
    }

    @ViewBuilder
    var apiOrNetworkErrorLabel: some View {
        switch viewModel.failedState {
        case .api(let msg), .network(let msg):
            Text(msg)
                .font(.regular(.footnote))
                .foregroundColor(.loginRegisterFailedField)
                .frame(maxWidth: .infinity, alignment: .leading)
        default:
            EmptyView()
        }
    }

    func signUpButton(ignoreEmailCheck: Bool) -> some View {
        AuthActionButton(
            title: TextsAsset.Welcome.signup,
            isEnabled: viewModel.isContinueButtonEnabled,
            isLoading: viewModel.showLoadingView
        ) {
            focusedField = nil
            viewModel.continueButtonTapped(ignoreEmailCheck: ignoreEmailCheck)
        }
    }

    @ViewBuilder
    var setupLaterButton: some View {
        if claimGhostAccount {
            Button(action: { dismiss() }) {
                Text(TextsAsset.setupLater)
                    .foregroundColor(.welcomeButtonTextColor)
                    .font(.bold(.title3))
                    .padding(.top, 12)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    var loginLink: some View {
        Button(action: { navigateToLogin = true }) {
            HStack(spacing: 4) {
                Text("\(TextsAsset.alreadyHaveAccount) \(TextsAsset.Welcome.login)")
                    .font(.regular(.callout))
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
    }

    func binding<Value>(_ keyPath: ReferenceWritableKeyPath<SignUpScreenViewModel, Value>) -> Binding<Value> {
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

// MARK: - Toolbar / Focus

@available(iOS 17.0, *)
private extension SignUpContentView {
    @ToolbarContentBuilder
    func signupToolbar() -> some ToolbarContent {
        AuthTabPickerToolbarItem(
            selectedTab: binding(\.selectedTab),
            isVisible: !claimGhostAccount
        )
        ToolbarItemGroup(placement: .keyboard) {
            Button(action: { moveFocus(up: true) }) {
                Image(systemName: "chevron.up")
            }
            .disabled(focusedField == .username)

            Button(action: { moveFocus(up: false) }) {
                Image(ImagesAsset.chevronDown)
            }
            .disabled(isLastFieldFocused)

            Spacer()

            Button(TextsAsset.Authentication.done) {
                focusedField = nil
            }
        }
    }

    func moveFocus(up: Bool) {
        guard let current = focusedField else { return }

        let allFields: [Field] = {
            var fields: [Field] = [.username, .password, .confirmPassword, .email]
            if viewModel.isVoucherVisible { fields.append(.voucher) }
            if viewModel.isReferralVisible { fields.append(.referral) }
            return fields
        }()

        guard let currentIndex = allFields.firstIndex(of: current) else { return }
        focusedField = allFields[up ? max(currentIndex - 1, 0) : min(currentIndex + 1, allFields.count - 1)]
    }

    func scrollToField(_ field: Field, proxy: ScrollViewProxy, geometry: GeometryProxy) {
        let anchorId = "\(field)-anchor"
        guard let anchor = fieldPositions[anchorId] else { return }
        let fieldRect = geometry[anchor]
        let visibleBottomY = geometry.size.height - 60

        if fieldRect.maxY > visibleBottomY {
            withAnimation { proxy.scrollTo(field, anchor: .top) }
        }
    }
}

// MARK: - Error helpers / hash formatting

@available(iOS 17.0, *)
private extension SignUpContentView {
    var isUsernameError: Bool {
        if case .username = viewModel.failedState { return true }
        return false
    }

    var usernameErrorMessage: String? {
        if case .username(let msg) = viewModel.failedState { return msg }
        return nil
    }

    var isPasswordError: Bool {
        if case .password = viewModel.failedState { return true }
        return false
    }

    var passwordErrorMessage: String? {
        if case .password(let msg) = viewModel.failedState { return msg }
        return nil
    }

    var isConfirmPasswordError: Bool {
        if case .confirmPassword = viewModel.failedState { return true }
        return false
    }

    var confirmPasswordErrorMessage: String? {
        if case .confirmPassword(let msg) = viewModel.failedState { return msg }
        return nil
    }

    var isEmailError: Bool {
        if case .email = viewModel.failedState { return true }
        return false
    }

    var emailErrorMessage: String? {
        if case .email(let msg) = viewModel.failedState { return msg }
        return nil
    }

    func showCopiedFeedback() {
        copyFeedbackResetTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) { isShowingCopiedFeedback = true }

        let task = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.2)) { isShowingCopiedFeedback = false }
            copyFeedbackResetTask = nil
        }
        copyFeedbackResetTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: task)
    }

    func hideCopiedFeedback() {
        copyFeedbackResetTask?.cancel()
        copyFeedbackResetTask = nil
        isShowingCopiedFeedback = false
    }
}

@available(iOS 17.0, *)
private extension String {
    func formattedHash(splitAt position: Int) -> String {
        guard count > position else { return self }
        let index = self.index(startIndex, offsetBy: position)
        return String(self[..<index]) + "\n" + String(self[index...])
    }
}

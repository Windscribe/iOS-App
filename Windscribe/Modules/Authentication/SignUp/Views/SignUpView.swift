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
    @Environment(\.dynamicTypeDefaultRange) private var dynamicTypeRange

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
                ScrollView {
                    VStack(spacing: 20) {
                        // Username Field
                        LoginTextField(
                            title: TextsAsset.chooseUsername,
                            placeholder: TextsAsset.Authentication.enterUsername,
                            showError: isUsernameError,
                            errorMessage: usernameErrorMessage,
                            showWarningIcon: showUsernameIcon,
                            text: $viewModel.username
                        )
                        .focused($focusedField, equals: .username)
                        .id(Field.username)
                        .readingFrame(id: "username-anchor")

                        // Password Field
                        LoginTextField(
                            title: TextsAsset.choosePassword,
                            placeholder: TextsAsset.Authentication.enterPassword,
                            isSecure: true,
                            showError: isPasswordError,
                            errorMessage: passwordErrorMessage,
                            showWarningIcon: showPasswordIcon,
                            text: $viewModel.password
                        )
                        .focused($focusedField, equals: .password)
                        .id(Field.password)
                        .readingFrame(id: "password-anchor")

                        // Email Field
                        VStack(spacing: 6) {
                            LoginTextField(
                                title: "\(TextsAsset.email) (\(TextsAsset.optional))",
                                placeholder: TextsAsset.Authentication.enterEmailAddress,
                                showError: isEmailError,
                                errorMessage: emailErrorMessage,
                                showWarningIcon: showEmailIcon,
                                text: $viewModel.email,
                                keyboardType: .emailAddress,
                                trailingView: AnyView(
                                    Text(TextsAsset.get10GbAMonth)
                                        .font(.medium(.callout))
                                        .foregroundColor(.white.opacity(0.5))
                                )
                            )
                            .focused($focusedField, equals: .email)
                            .id(Field.email)
                            .readingFrame(id: "email-anchor")

                            Text(TextsAsset.emailInfoLabel)
                                .font(.regular(.footnote))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Voucher Code Field
                        LoginTextField(
                            title: "\(TextsAsset.voucherCode) (\(TextsAsset.optional))",
                            placeholder: TextsAsset.Authentication.enterVoucherCode,
                            text: $viewModel.voucherCode
                        )
                        .focused($focusedField, equals: .voucher)
                        .id(Field.voucher)
                        .readingFrame(id: "voucher-anchor")

                        if !signupFlowContext.isFromGhostAccount {
                            // Referral Toggle
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    viewModel.referralViewTapped()
                                }
                            },label: {
                                HStack(spacing: 8) {
                                    Text(TextsAsset.referredBySomeone)
                                        .font(.medium(.callout))
                                        .foregroundColor(.white)

                                    Image(systemName: "chevron.down")
                                        .rotationEffect(.degrees(viewModel.isReferralVisible ? 180 : 0))
                                        .foregroundColor(.white.opacity(0.5))
                                        .animation(.easeInOut(duration: 0.25), value: viewModel.isReferralVisible)
                                }
                            })
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Referral Section
                        if viewModel.isReferralVisible {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 6) {
                                    Text("✓")
                                        .foregroundColor(.green)
                                        .font(.regular(.callout))
                                    Text(TextsAsset.youWillBothGetTenGb)
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.regular(.callout))
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                HStack(alignment: .top, spacing: 6) {
                                    Text("✓")
                                        .foregroundColor(.green)
                                        .font(.regular(.callout))
                                    Text(TextsAsset.ifYouGoPro)
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.regular(.callout))
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                // TextField
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
                                    text: $viewModel.referralUsername
                                )
                                .disabled(!viewModel.isEmailValid(viewModel.email))
                                .focused($focusedField, equals: .referral)
                                .id(Field.referral)
                                .readingFrame(id: "referral-anchor")

                                // Info
                                Text(TextsAsset.mustConfirmEmail)
                                    .font(.regular(.footnote))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.25), value: viewModel.isReferralVisible)
                        }

                        // API or Network Error
                        if let errorText = apiOrNetworkError {
                            Text(errorText)
                                .font(.regular(.footnote))
                                .foregroundColor(.loginRegisterFailedField)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Continue Button
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
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isContinueButtonEnabled ? Color.loginRegisterEnabledButtonColor : Color.white)
                            .clipShape(Capsule())
                        }
                        .disabled(!viewModel.isContinueButtonEnabled || viewModel.showLoadingView)

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
                    .padding()
                    .padding(.bottom, keyboard.currentHeight) // Dynamic keyboard-aware padding
                    .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
                    .background( // Needed for anchor resolution
                        GeometryReader { _ in
                            Color.clear
                                .onPreferenceChange(ViewFrameKey.self) { prefs in
                                    self.fieldPositions = prefs
                                }
                        }
                    )
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
                .fullScreenCover(isPresented: $showEmailWarning) {
                    SignupWarningView(
                        onContinue: {
                            showEmailWarning = false
                            viewModel.continueButtonTapped(ignoreEmailCheck: true, claimAccount: false)
                        },
                        onBack: {
                            showEmailWarning = false
                        }
                    )
                }
            }
        }
        .background(Color.loginRegisterBackgroundColor)
        .dynamicTypeSize(dynamicTypeRange)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(signupFlowContext.isFromGhostAccount ? TextsAsset.accountSetupTitle : TextsAsset.createAccount)
                    .foregroundColor(.white)
                    .font(.headline)
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "chevron.backward")
                      .font(.system(size: 17, weight: .semibold))
                      .foregroundColor(.white)
                      .padding(.leading, -8)
                })
            }

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
                .disabled(isLastFieldFocused)

                Spacer()

                Button(TextsAsset.Authentication.done) {
                    focusedField = nil
                }
            }
        }

    }

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

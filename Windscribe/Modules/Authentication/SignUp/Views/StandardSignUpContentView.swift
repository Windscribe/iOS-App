//
//  StandardSignUpContentView.swift
//  Windscribe
//
//  Created by Anthony on 2026-04-01.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

struct StandardSignUpContentView: View {

    @ObservedObject var viewModel: SignUpViewModelImpl
    @EnvironmentObject var signupFlowContext: SignupFlowContext

    var focusedField: FocusState<SignUpView.Field?>.Binding
    var onSignUp: () -> Void
    var onLogin: () -> Void
    var onDismiss: () -> Void

    @State private var forcePasswordVisible = false

    var body: some View {
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
            signUpButton
                .padding(.top, viewModel.isReferralVisible ? 0 : 20)
            setupLaterButton
            Spacer()
            loginLink
        }
    }
}

// MARK: - Error Helpers

private extension StandardSignUpContentView {

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

    var apiOrNetworkError: String? {
        switch viewModel.failedState {
        case .api(let msg): return msg
        case .network(let msg): return msg
        default: return nil
        }
    }
}

// MARK: - Subviews

private extension StandardSignUpContentView {

    @ViewBuilder
    var usernameField: some View {
        LoginTextField(
            title: TextsAsset.chooseUsername,
            placeholder: TextsAsset.Authentication.enterUsername,
            showError: isUsernameError,
            errorMessage: usernameErrorMessage,
            showWarningIcon: isUsernameError,
            text: $viewModel.username,
            isDarkMode: $viewModel.isDarkMode,
            trailingView: AnyView(
                Button(action: { viewModel.generateUsername() }) {
                    Image(ImagesAsset.arrowRefresh)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                }
                .buttonStyle(.plain)
            )
        )
        .focused(focusedField, equals: .username)
        .id(SignUpView.Field.username)
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
            showWarningIcon: isPasswordError,
            text: $viewModel.password,
            isDarkMode: $viewModel.isDarkMode,
            passwordVisible: $forcePasswordVisible,
            trailingView: AnyView(
                Button(action: {
                    forcePasswordVisible = true
                    viewModel.generatePassword()
                }) {
                    Image(ImagesAsset.arrowRefresh)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                }
                .buttonStyle(.plain)
            )
        )
        .focused(focusedField, equals: .password)
        .id(SignUpView.Field.password)
        .readingFrame(id: "password-anchor")
    }

    @ViewBuilder
    var confirmPasswordField: some View {
        LoginTextField(
            title: "",
            placeholder: TextsAsset.confirmPassword,
            isSecure: true,
            showPasswordToggle: false,
            showError: isConfirmPasswordError,
            errorMessage: confirmPasswordErrorMessage,
            showWarningIcon: isConfirmPasswordError,
            text: $viewModel.confirmPassword,
            isDarkMode: $viewModel.isDarkMode,
            passwordVisible: $forcePasswordVisible,
            trailingView: AnyView(
                Button(action: {
                    UIPasteboard.general.string = viewModel.password
                    Assembler.resolve(AlertManager.self).showSimpleAlert(
                        title: "",
                        message: TextsAsset.copiedToClipboard,
                        buttonText: TextsAsset.okay
                    )
                }) {
                    Image(ImagesAsset.copyClipboard)
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                }
                .buttonStyle(.plain)
            )
        )
        .focused(focusedField, equals: .confirmPassword)
        .id(SignUpView.Field.confirmPassword)
        .readingFrame(id: "confirmPassword-anchor")
    }

    @ViewBuilder
    var emailField: some View {
        VStack(spacing: 6) {
            HStack {
                Text(TextsAsset.addEmail)
                    .font(.medium(.callout))
                    .foregroundColor(isEmailError
                                     ? .loginRegisterFailedField
                                     : .from(.titleColor, viewModel.isDarkMode))

                Spacer()

                OptionalPill(isDarkMode: $viewModel.isDarkMode)
            }

            LoginTextField(
                title: "",
                placeholder: TextsAsset.Authentication.enterEmailAddress,
                showError: isEmailError,
                errorMessage: emailErrorMessage,
                showWarningIcon: false,
                text: $viewModel.email,
                isDarkMode: $viewModel.isDarkMode,
                keyboardType: .emailAddress,
                trailingView: AnyView(
                    InfoAlertButton(
                        title: TextsAsset.addEmail,
                        message: TextsAsset.emailInfoLabel,
                        isDarkMode: $viewModel.isDarkMode
                    )
                )
            )
        }
        .focused(focusedField, equals: .email)
        .id(SignUpView.Field.email)
        .readingFrame(id: "email-anchor")
    }

    @ViewBuilder
    var voucherToggle: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.voucherViewTapped()
            }
        }) {
            HStack {
                Text(TextsAsset.gotVoucherCode)
                    .font(.medium(.callout))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                Spacer()

                OptionalPill(isDarkMode: $viewModel.isDarkMode)

                Image(ImagesAsset.chevronDown)
                    .font(.caption)
                    .rotationEffect(.degrees(viewModel.isVoucherVisible ? 180 : 0))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
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
                text: $viewModel.voucherCode,
                isDarkMode: $viewModel.isDarkMode
            )
            .focused(focusedField, equals: .voucher)
            .id(SignUpView.Field.voucher)
            .readingFrame(id: "voucher-anchor")
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isVoucherVisible)
        }
    }

    @ViewBuilder
    var referralToggle: some View {
        if !signupFlowContext.isFromGhostAccount {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.referralViewTapped()
                }
            }, label: {
                HStack {
                    Text(TextsAsset.referredBySomeone)
                        .font(.medium(.callout))
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                    Spacer()

                    OptionalPill(isDarkMode: $viewModel.isDarkMode)

                    Image(ImagesAsset.chevronDown)
                        .font(.caption)
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
                        Text("\u{2713}")
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
                .focused(focusedField, equals: .referral)
                .id(SignUpView.Field.referral)
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
    var signUpButton: some View {
        AuthActionButton(
            title: TextsAsset.Welcome.signup,
            isEnabled: viewModel.isContinueButtonEnabled,
            isLoading: viewModel.showLoadingView,
            action: onSignUp
        )
    }

    @ViewBuilder
    var loginLink: some View {
        Button(action: {
            onLogin()
        }) {
            HStack(spacing: 4) {
                Text("\(TextsAsset.alreadyHaveAccount) \(TextsAsset.Welcome.login)")
                    .font(.regular(.callout))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
    }

    @ViewBuilder
    var setupLaterButton: some View {
        if signupFlowContext.isFromGhostAccount {
            Button(action: {
                onDismiss()
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
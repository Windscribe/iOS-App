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
    @EnvironmentObject var router: LoginNavigationRouter

    @ObservedObject private var keyboard = KeyboardResponder()
    @StateObject private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?
    @State private var safariURL: URL?

    // MARK: - Error Flags
    private var isUsernameError: Bool {
        if case .username = viewModel.failedState { return true }
        if case .api = viewModel.failedState { return true }
        return false
    }

    private var usernameErrorMessage: String? {
        if case .username(let msg) = viewModel.failedState { return msg }
        if case .api(let msg) = viewModel.failedState { return msg }
        return nil
    }

    private var showUsernameIcon: Bool { isUsernameError }

    private var isPasswordError: Bool {
        if case .api = viewModel.failedState { return true }
        return false
    }

    private var passwordErrorMessage: String? {
        if case .api(let msg) = viewModel.failedState { return msg }
        return nil
    }

    private var showPasswordIcon: Bool { isPasswordError }

    private var isTwoFaError: Bool {
        if case .twoFa = viewModel.failedState { return true }
        return false
    }

    private var showTwoFaIcon: Bool { isTwoFaError }

    // MARK: - Init
    init(viewModel: LoginViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - View
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    // Username Field
                    LoginTextField(
                        title: TextsAsset.Authentication.username,
                        placeholder: TextsAsset.Authentication.enterUsername,
                        showError: isUsernameError,
                        errorMessage: usernameErrorMessage,
                        showWarningIcon: showUsernameIcon,
                        showFieldErrorText: false,
                        text: $viewModel.username
                    )
                    .focused($focusedField, equals: .username)
                    .id(Field.username)

                    // Password Field
                    LoginTextField(
                        title: TextsAsset.Authentication.password,
                        placeholder: TextsAsset.Authentication.enterPassword,
                        isSecure: true,
                        showError: isPasswordError,
                        errorMessage: passwordErrorMessage,
                        showWarningIcon: showPasswordIcon,
                        showFieldErrorText: false,
                        text: $viewModel.password
                    )
                    .focused($focusedField, equals: .password)
                    .id(Field.password)

                    // 2FA Field
                    if viewModel.show2FAField {
                        VStack(alignment: .leading, spacing: 8) {
                            LoginTextField(
                                title: TextsAsset.Authentication.twoFactorCode,
                                placeholder: "",
                                showError: isTwoFaError,
                                showWarningIcon: showTwoFaIcon,
                                showFieldErrorText: false,
                                text: $viewModel.twoFactorCode
                            )
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .twoFactorCode)
                            .id(Field.twoFactorCode)

                            Text(TextsAsset.Authentication.twoFactorDescription)
                                .font(.regular(.footnote))
                                .foregroundColor(.gray)
                        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.show2FAField)
                    }

                    // 2FA & Forgot Password
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
                            .foregroundColor(.gray)
                            .font(.medium(.callout))
                        }

                        Spacer()

                        Button(TextsAsset.Authentication.forgotPassword) {
                            safariURL = URL(string: Links.forgotPassword)
                        }
                        .foregroundColor(.gray)
                        .font(.medium(.callout))
                    }
                    .padding(.top, 4)

                    // Error Display
                    if let error = viewModel.failedState {
                        Text(errorMessage(for: error))
                            .foregroundColor(.loginRegisterFailedField)
                            .font(.regular(.footnote))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Continue Button
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
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isContinueButtonEnabled ? Color.loginRegisterEnabledButtonColor : Color.white)
                        .clipShape(Capsule())
                    }
                    .disabled(!viewModel.isContinueButtonEnabled || viewModel.showLoadingView)
                }
                .padding()
                .padding(.bottom, keyboard.currentHeight)
                .animation(.easeOut(duration: 0.25), value: keyboard.currentHeight)
            }
            .onChange(of: focusedField) { field in
                if let field = field {
                    withAnimation {
                        proxy.scrollTo(field, anchor: .center)
                    }
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
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
        }
        .padding(.top, 1)
        .background(Color(UIColor(red: 0.043, green: 0.059, blue: 0.086, alpha: 1)))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(TextsAsset.Welcome.login)
                    .foregroundColor(.white)
                    .font(.headline)
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                })
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - Error Mapping
    private func errorMessage(for state: LoginErrorState) -> String {
        switch state {
        case .username(let error): return error
        case .network(let error): return error
        case .twoFa(let error): return error
        case .api(let error): return error
        case .loginCode(let error): return error
        }
    }
}

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
    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

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
                        .readingFrame(id: "username-anchor")

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
                        .readingFrame(id: "password-anchor")

                        // 2FA Field
                        if viewModel.show2FAField {
                            VStack(alignment: .leading, spacing: 8) {
                                LoginTextField(
                                    title: TextsAsset.Authentication.twoFactorCode,
                                    placeholder: "",
                                    showError: isTwoFaError,
                                    showWarningIcon: showTwoFaIcon,
                                    showFieldErrorText: false,
                                    text: $viewModel.twoFactorCode,
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
                                    .foregroundColor(.white.opacity(0.5))
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
                                .foregroundColor(.white.opacity(0.5))
                                .font(.medium(.callout))
                            }

                            Spacer()

                            Button(TextsAsset.Authentication.forgotPassword) {
                                safariURL = URL(string: Links.forgotPassword)
                            }
                            .foregroundColor(.white.opacity(0.5))
                            .font(.medium(.callout))
                        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.show2FAField)

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
                            .background(viewModel.isContinueButtonEnabled
                                        ? Color.loginRegisterEnabledButtonColor
                                        : Color.white)
                            .clipShape(Capsule())
                        }
                        .disabled(!viewModel.isContinueButtonEnabled || viewModel.showLoadingView)
                    }
                    .padding()
                    .padding(.bottom, keyboard.currentHeight + 16)
                    .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
                    .background(
                        GeometryReader { _ in
                            Color.clear
                                .onPreferenceChange(ViewFrameKey.self) { prefs in
                                    self.fieldPositions = prefs
                                }
                        }
                    )
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
            .sheet(item: $safariURL) { url in
                  SafariView(url: url)
            }
            .padding(.top, 1)
            .background(Color.loginRegisterBackgroundColor)
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
                  .padding(.leading, 8)
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
                  .disabled(focusedField == .twoFactorCode || (!viewModel.show2FAField && focusedField == .password))

                  Spacer()

                  Button(TextsAsset.Authentication.done) {
                      focusedField = nil
                  }
              }
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
    }

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

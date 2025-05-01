//
//  EnterEmailView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-10.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct EnterEmailView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    @StateObject private var keyboard = KeyboardResponder()
    @FocusState private var isEmailFocused: Bool

    @StateObject var viewModel: EnterEmailViewModelImpl
    @State private var currentError: String?

    init(viewModel: any EnterEmailViewModel) {
        guard let model = viewModel as? EnterEmailViewModelImpl else {
            fatalError("EnterEmailView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ScrollView {

            VStack(alignment: .leading, spacing: 20) {
                // Email Input
                LoginTextField(
                    title: TextsAsset.yourEmail,
                    placeholder: TextsAsset.Authentication.enterEmailAddress,
                    showError: currentError != nil,
                    errorMessage: currentError,
                    showWarningIcon: currentError != nil,
                    showFieldErrorText: true,
                    text: $viewModel.email,
                    keyboardType: .emailAddress,
                    trailingView: viewModel.showGet10GBPromo
                        ? AnyView(
                            Text(TextsAsset.get10GbAMonth)
                                .font(.medium(.callout))
                                .foregroundColor(.white.opacity(0.5))
                        )
                        : nil
                )
                .focused($isEmailFocused)

                // Info Text
                Text(viewModel.infoLabelText)
                    .font(.regular(.footnote))
                    .dynamicTypeSize(dynamicTypeRange)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Continue Button
                Button {
                    isEmailFocused = false
                    viewModel.submit()
                } label: {
                    ZStack {
                        if viewModel.showLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text(TextsAsset.continue)
                                .font(.bold(.body))
                                .dynamicTypeSize(dynamicTypeRange)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.emailIsValid ? Color.loginRegisterEnabledButtonColor : Color.white)
                    .clipShape(Capsule())
                }
                .disabled(!viewModel.emailIsValid)
            }
            .padding()
            .padding(.bottom, keyboard.currentHeight + 16)
            .dynamicTypeSize(dynamicTypeRange)
            .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
        }
        .onTapGesture {
            isEmailFocused = false
        }
        .onReceive(viewModel.submitEmailResult) { result in
            switch result {
            case .success:
                currentError = nil
                // TODO: Confirm Email Navigation
            case .failure(let error):
                currentError = error.errorDescription
            }
        }
        .padding(.top, 1)
        .background(Color.loginRegisterBackgroundColor)
        .dynamicTypeSize(dynamicTypeRange)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Add Email")
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

        }
    }
}

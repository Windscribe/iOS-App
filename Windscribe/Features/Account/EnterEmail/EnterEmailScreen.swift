//
//  EnterEmailScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-09.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

/// Top-level navigation destination for adding an account email. Reads
/// `@Environment`, constructs the view model, hands it to the inner view.
@available(iOS 17.0, *)
struct EnterEmailScreen: View {
    @Environment(\.sessionProviding) private var sessionProvider
    @Environment(\.accountManaging) private var accountManager

    let onSubmitted: () -> Void

    init(onSubmitted: @escaping () -> Void = { }) {
        self.onSubmitted = onSubmitted
    }

    var body: some View {
        let viewModel = EnterEmailFeatureViewModel(
            sessionProvider: sessionProvider,
            accountManager: accountManager
        )

        EnterEmailContentView(viewModel: viewModel, onSubmitted: onSubmitted)
            .navigationTitle(TextsAsset.addEmail)
            .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct EnterEmailContentView: View {
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange
    @Environment(\.lookAndFeel) private var lookAndFeel

    @FocusState private var isEmailFocused: Bool
    @State private var viewModel: EnterEmailFeatureViewModel

    let onSubmitted: () -> Void

    init(viewModel: EnterEmailFeatureViewModel, onSubmitted: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSubmitted = onSubmitted
    }

    var body: some View {
        @Bindable var bindable = viewModel

        BaseContentView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LoginTextField(
                        title: TextsAsset.yourEmail,
                        placeholder: TextsAsset.Authentication.enterEmailAddress,
                        showError: viewModel.currentError != nil,
                        errorMessage: viewModel.currentError,
                        showWarningIcon: viewModel.currentError != nil,
                        showFieldErrorText: true,
                        text: $bindable.email,
                        keyboardType: .emailAddress,
                        trailingView: trailingPromoView
                    )
                    .focused($isEmailFocused)

                    Text(viewModel.infoLabelText)
                        .font(.regular(.footnote))
                        .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode).opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    continueButton
                }
                .padding()
                .dynamicTypeSize(dynamicTypeRange)
            }
            .onTapGesture {
                isEmailFocused = false
            }
        }
        .task {
            await viewModel.startObservers()
        }
        .onChange(of: viewModel.didSubmitEmail) { didSubmit in
            guard didSubmit else { return }
            onSubmitted()
        }
    }

    private var trailingPromoView: AnyView? {
        guard viewModel.showGet10GBPromo else { return nil }

        return AnyView(
            Text(viewModel.emailInfoText)
                .font(.medium(.callout))
                .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode).opacity(0.5))
        )
    }

    private var continueButton: some View {
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
                        .foregroundColor(.from(.actionBackgroundColor, lookAndFeel.isDarkMode))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.emailIsValid
                        ? Color.loginRegisterEnabledButtonColor
                        : .from(.iconColor, lookAndFeel.isDarkMode))
            .clipShape(Capsule())
        }
        .disabled(!viewModel.emailIsValid)
        .buttonStyle(.plain)
    }
}

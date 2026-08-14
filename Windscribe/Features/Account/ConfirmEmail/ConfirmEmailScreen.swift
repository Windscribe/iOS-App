//
//  ConfirmEmailScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-09.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

/// Top-level navigation destination for confirming an account email. Reads
/// `@Environment`, constructs the view model, hands it to the inner view.
@available(iOS 17.0, *)
struct ConfirmEmailScreen: View {
    @Environment(\.sessionProviding) private var sessionProvider
    @Environment(\.accountManaging) private var accountManager

    let openEnterEmail: () -> Void
    let onDismiss: () -> Void

    init(openEnterEmail: @escaping () -> Void = { },
         onDismiss: @escaping () -> Void = { }) {
        self.openEnterEmail = openEnterEmail
        self.onDismiss = onDismiss
    }

    var body: some View {
        let viewModel = ConfirmEmailScreenViewModel(
            sessionProvider: sessionProvider,
            accountManager: accountManager
        )

        ConfirmEmailContentView(
            viewModel: viewModel,
            openEnterEmail: openEnterEmail,
            onDismiss: onDismiss
        )
    }
}

@available(iOS 17.0, *)
private struct ConfirmEmailContentView: View {
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.lookAndFeel) private var lookAndFeel

    @State private var viewModel: ConfirmEmailScreenViewModel

    let openEnterEmail: () -> Void
    let onDismiss: () -> Void

    init(viewModel: ConfirmEmailScreenViewModel,
         openEnterEmail: @escaping () -> Void,
         onDismiss: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.openEnterEmail = openEnterEmail
        self.onDismiss = onDismiss
    }

    var body: some View {
        @Bindable var bindable = viewModel

        BaseContentView {
            contentView
        }
        .dynamicTypeSize(dynamicTypeRange)
        .task {
            await viewModel.startObservers()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            viewModel.updateSession()
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            guard shouldDismiss else { return }
            onDismiss()
        }
        .alert(TextsAsset.ConfirmationEmailSentAlert.title,
               isPresented: $bindable.showingResendSuccessAlert) {
            Button(TextsAsset.okay, role: .cancel) { }
        } message: {
            Text(TextsAsset.ConfirmationEmailSentAlert.message)
        }
    }

    private var contentView: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                Image(ImagesAsset.confirmEmail)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))
                    .frame(width: 68, height: 68)

                Text(TextsAsset.EmailView.confirmEmail)
                    .font(.bold(.title2))
                    .dynamicTypeSize(dynamicTypeRange)
                    .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                    .multilineTextAlignment(.center)

                Text(viewModel.session?.shouldShowEmailPromo == true ? TextsAsset.EmailView.info : TextsAsset.EmailView.infoPro)
                    .font(.text(.callout))
                    .dynamicTypeSize(dynamicTypeRange)
                    .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode).opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)

                outlineButton(
                    title: TextsAsset.EmailView.resendEmail,
                    disabled: viewModel.resendButtonDisabled,
                    action: viewModel.resendEmail
                )
                .opacity(viewModel.resendButtonDisabled ? 0.35 : 1.0)

                outlineButton(
                    title: TextsAsset.EmailView.changeEmail,
                    action: openEnterEmail
                )

                Button {
                    viewModel.closeSelected()
                } label: {
                    Text(TextsAsset.EmailView.close)
                        .font(.bold(.callout))
                        .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode).opacity(0.5))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func outlineButton(title: String,
                               disabled: Bool = false,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.text(.callout))
                .dynamicTypeSize(dynamicTypeRange)
                .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode).opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.from(.titleColor, lookAndFeel.isDarkMode), lineWidth: 2)
                )
        }
        .disabled(disabled)
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }
}

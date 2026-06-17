//
//  AccountScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-09.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

/// Top-level navigation destination for Account preferences. Reads
/// `@Environment`, constructs the view model, hands it to the inner view.
@available(iOS 17.0, *)
struct AccountScreen: View {
    @Environment(\.hapticFeedback) private var hapticFeedback
    @Environment(\.sessionProviding) private var sessionProvider
    @Environment(\.accountManaging) private var accountManager
    @Environment(\.preferencesReading) private var preferencesReading
    @Environment(\.ssoManaging) private var ssoManaging
    @Environment(\.logger) private var logger

    let openEnterEmail: () -> Void

    init(openEnterEmail: @escaping () -> Void = { }) {
        self.openEnterEmail = openEnterEmail
    }

    var body: some View {
        let viewModel = AccountViewModel(
            hapticFeedback: hapticFeedback,
            sessionProvider: sessionProvider,
            accountManager: accountManager,
            preferencesReading: preferencesReading,
            ssoManaging: ssoManaging,
            logger: logger
        )

        AccountContentView(viewModel: viewModel, openEnterEmail: openEnterEmail)
            .navigationTitle(TextsAsset.Account.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct AccountContentView: View {
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange
    @Environment(\.lookAndFeel) private var lookAndFeel

    @State private var viewModel: AccountViewModel
    @State private var inputText = ""
    @State private var dialog: AccountInputDialog?
    @State private var showUpgradeModal = false
    @State private var upgradePromoCode: String?
    @State private var hasLoaded = false
    @State private var showCustomLazyLoginAlert = false

    let openEnterEmail: () -> Void

    init(viewModel: AccountViewModel, openEnterEmail: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.openEnterEmail = openEnterEmail
    }

    var body: some View {
        @Bindable var bindable = viewModel
        ZStack {
            if case let .loading(isFullScreen) = viewModel.loadingState, isFullScreen {
                MenuLoadingOverlayView(isFullScreen: true)
            } else {
                content
            }

            if case let .loading(isFullScreen) = viewModel.loadingState, !isFullScreen {
                MenuLoadingOverlayView(isFullScreen: false)
            }
        }
        .fullScreenCover(isPresented: $bindable.showPasswordResetSuccess) {
            PasswordResetSuccessView(
                isDarkMode: lookAndFeel.isDarkMode,
                onClose: viewModel.dismissPasswordResetSuccess
            )
        }
        .dynamicTypeSize(dynamicTypeRange)
        .alert(item: $bindable.alertMessage) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(alert.buttonText))
            )
        }
        .alert(dialogTitle(dialog), isPresented: Binding<Bool>(
            get: { dialog != nil && dialog != .lazyLogin },
            set: { if !$0 { dialog = nil } }
        ), actions: {
            dialogInputField
            Button(TextsAsset.confirm) {
                handleConfirm(dialog: dialog, input: inputText)
            }

            Button(TextsAsset.cancel, role: .cancel) { }
        }, message: {
            Text(dialogDescription(dialog))
        })
        .id(dialog?.id)
        .sheet(isPresented: $showUpgradeModal) {
            if let promoCode = upgradePromoCode {
                PlanUpgradeViewControllerWrapper(promoCode: promoCode, pcpID: nil)
                    .edgesIgnoringSafeArea(.all)
            } else {
                PlanUpgradeViewControllerWrapper()
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .overlay(lazyLoginOverlay)
        .task {
            await viewModel.startObservers()
        }
        .onAppear {
            viewModel.actionSelected()
            guard !hasLoaded else { return }
            hasLoaded = true
            Task { await viewModel.loadSession() }
        }
    }

    @ViewBuilder
    private var dialogInputField: some View {
        if dialog == .password {
            SecureField(dialogPlaceHolder(dialog), text: $inputText)
        } else if dialog == .accountHash {
            TextField(dialogPlaceHolder(dialog), text: $inputText, axis: .vertical)
                .lineLimit(2, reservesSpace: true)
        } else if dialog != .appleSSO {
            TextField(dialogPlaceHolder(dialog), text: $inputText)
        } else {
            EmptyView()
        }
    }

    private var content: some View {
        BaseContentView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(viewModel.sections) { section in
                        AccountFeatureSectionView(
                            isDarkMode: lookAndFeel.isDarkMode,
                            section: section,
                            accountStatus: viewModel.accountEmailStatus,
                            handleRowAction: viewModel.handleRowAction,
                            presentDialog: presentDialog
                        )

                        if section.type == .info, viewModel.shouldShowAddEmailButton {
                            infoActionButton
                        }

                        if section.type == .plan {
                            planActionButtons
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var infoActionButton: some View {
        AccountActionButton(
            title: TextsAsset.Account.addEmailActionTitle,
            foregroundColor: .from(.titleColor, lookAndFeel.isDarkMode),
            backgroundColor: .from(.backgroundColor, lookAndFeel.isDarkMode)
        ) {
            viewModel.actionSelected()
            openEnterEmail()
        }
    }

    private var planActionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.shouldShowUpgradeButton {
                AccountActionButton(
                    title: TextsAsset.Account.upgradeToProActionTitle,
                    foregroundColor: .actionBlue,
                    backgroundColor: Color.actionBlue.opacity(0.15)
                ) {
                    viewModel.actionSelected()
                    showUpgradeModal = true
                }
            }

            if viewModel.shouldShowDeleteAccountButton {
                AccountActionButton(
                    title: TextsAsset.Account.cancelAccount,
                    foregroundColor: .from(.titleColor, lookAndFeel.isDarkMode),
                    backgroundColor: .from(.backgroundColor, lookAndFeel.isDarkMode)
                ) {
                    viewModel.actionSelected()
                    presentDialog(for: viewModel.accountDeletionDialog)
                }
            }

            if viewModel.shouldShowResetPasswordButton && !viewModel.resetPasswordButtonHidden {
                AccountActionButton(
                    title: TextsAsset.Account.resetPasswordActionTitle,
                    foregroundColor: .from(.titleColor, lookAndFeel.isDarkMode),
                    backgroundColor: .from(.backgroundColor, lookAndFeel.isDarkMode)
                ) {
                    viewModel.resetPassword()
                }
            }
        }
    }

    private var lazyLoginOverlay: some View {
        ZStack {
            if showCustomLazyLoginAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        showCustomLazyLoginAlert = false
                    }

                LazyLoginCodeAlertView(
                    title: TextsAsset.Account.loginCodeTitle,
                    message: TextsAsset.Account.lazyLoginDescription,
                    code: $inputText,
                    isDarkMode: lookAndFeel.isDarkMode,
                    onConfirm: {
                        showCustomLazyLoginAlert = false
                        handleConfirm(dialog: .lazyLogin, input: inputText)
                    },
                    onCancel: {
                        showCustomLazyLoginAlert = false
                        inputText = ""
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCustomLazyLoginAlert)
    }

    private func handleConfirm(dialog selectedDialog: AccountInputDialog?, input: String) {
        switch selectedDialog {
        case .password, .accountHash:
            viewModel.confirmCancelAccount(password: input)
        case .lazyLogin:
            viewModel.verifyLazyLogin(code: input)
        case .appleSSO:
            viewModel.confirmCancelAccountWithAppleSSO()
        case .none:
            break
        }

        dialog = nil
        inputText = ""
    }

    private func dialogTitle(_ dialog: AccountInputDialog?) -> String {
        guard let dialog else { return TextsAsset.Account.defaultDialogTitle }

        switch dialog {
        case .password, .accountHash, .appleSSO:
            return TextsAsset.Account.cancelAccount
        case .lazyLogin:
            return TextsAsset.Account.loginCodeTitle
        }
    }

    private func dialogDescription(_ dialog: AccountInputDialog?) -> String {
        guard let dialog else { return TextsAsset.Account.defaultDialogMessage }

        switch dialog {
        case .password:
            return TextsAsset.Account.deleteAccountMessage
        case .accountHash:
            return TextsAsset.Account.deleteAccountHashMessage
        case .lazyLogin:
            return TextsAsset.Account.lazyLoginDescription
        case .appleSSO:
            return TextsAsset.Account.deleteAccountAppleSSOMessage
        }
    }

    private func dialogPlaceHolder(_ dialog: AccountInputDialog?) -> String {
        guard let dialog else { return TextsAsset.Account.defaultDialogTitle }

        switch dialog {
        case .password:
            return TextsAsset.Account.accountPasswordTitle
        case .accountHash:
            return TextsAsset.accountHash
        case .lazyLogin:
            return TextsAsset.Account.loginCodeTitle
        case .appleSSO:
            return ""
        }
    }

    private func presentDialog(for type: AccountInputDialog) {
        inputText = ""
        if type == .lazyLogin {
            showCustomLazyLoginAlert = true
        } else {
            dialog = type
        }
    }
}

@available(iOS 17.0, *)
private struct AccountActionButton: View {
    let title: String
    let foregroundColor: Color
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .foregroundColor(foregroundColor)
                .font(.medium(.callout))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(14)
                .background(backgroundColor)
                .cornerRadius(12)
                .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 17.0, *)
private struct AccountFeatureSectionView: View {
    let isDarkMode: Bool
    let section: AccountSectionModel
    let accountStatus: AccountEmailStatusType
    let handleRowAction: (AccountRowAction) -> Void
    let presentDialog: (AccountInputDialog) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.type.title.uppercased())
                .font(.semiBold(.caption1))
                .foregroundColor(.from(.timeColor, isDarkMode))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            if section.type == .other {
                otherRows
            } else {
                standardRows
            }

            if section.type == .info, accountStatus == .unverified {
                resendEmailButton
            }
        }
    }

    private var otherRows: some View {
        ForEach(section.items.indices, id: \.self) { index in
            let row = section.items[index]
            AccountFeatureRowView(
                isDarkMode: isDarkMode,
                row: row,
                section: section.type,
                showDivider: false,
                accountStatus: accountStatus,
                actionHandler: handleAction
            )
            .background(Color.from(.backgroundColor, isDarkMode))
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }

    private var standardRows: some View {
        VStack(spacing: 0) {
            ForEach(section.items.indices, id: \.self) { index in
                let row = section.items[index]
                AccountFeatureRowView(
                    isDarkMode: isDarkMode,
                    row: row,
                    section: section.type,
                    showDivider: index < section.items.count - 1,
                    accountStatus: accountStatus,
                    actionHandler: handleAction
                )
            }
        }
        .background(Color.from(.backgroundColor, isDarkMode))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private var resendEmailButton: some View {
        Button {
            handleRowAction(.resendEmail)
        } label: {
            Text(TextsAsset.EmailView.resendEmail)
                .foregroundColor(.from(.titleColor, isDarkMode))
                .font(.medium(.callout))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(14)
                .background(Color.from(.backgroundColor, isDarkMode))
                .cornerRadius(12)
                .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private func handleAction(_ action: AccountRowAction) {
        switch action {
        case .openLazyLogin:
            presentDialog(.lazyLogin)
        case .cancelAccount:
            presentDialog(.password)
        case .resendEmail:
            handleRowAction(action)
        default:
            break
        }
    }
}

@available(iOS 17.0, *)
private struct AccountFeatureRowLeadingContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

@available(iOS 17.0, *)
private struct AccountFeatureRowContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

@available(iOS 17.0, *)
private struct AccountFeatureRowView: View {
    let isDarkMode: Bool
    let row: AccountRowModel
    let section: AccountSectionType
    let showDivider: Bool
    let accountStatus: AccountEmailStatusType
    let actionHandler: (AccountRowAction) -> Void

    @State private var showCopied = false
    @State private var leadingContentWidth: CGFloat = 0
    @State private var rowContentWidth: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            rowContent

            if let message = row.message, section == .other {
                Text(message)
                    .foregroundColor(.from(.infoColor, isDarkMode))
                    .font(.regular(.subheadline))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }

            if let subtitle = row.descriptionText(accountStatus: accountStatus) {
                Text(subtitle)
                    .foregroundColor(.from(.infoColor, isDarkMode))
                    .font(.regular(.footnote))
                    .padding(12)
            }

            if row.shouldShowConfirmEmailBanner(accountStatus: accountStatus) {
                Text(TextsAsset.EmailView.infoPro)
                    .foregroundColor(Color.orangeYellow)
                    .font(.medium(.footnote))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }

            if showDivider {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.from(.screenBackgroundColor, isDarkMode))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let action = row.action {
                actionHandler(action)
            }
        }
    }

    private var rowContent: some View {
        let maxLeadingWidth = rowContentWidth / 2
        let leadingWidth = rowContentWidth > 0 ? min(leadingContentWidth, maxLeadingWidth) : leadingContentWidth

        return HStack(alignment: .top, spacing: 6) {
            leadingContent
                .frame(width: leadingWidth, alignment: .leading)
                .hidden()
                .overlay(alignment: .leading) {
                    leadingContent
                        .frame(width: leadingWidth, alignment: .leading)
                        .clipped()
                }
                .background {
                    leadingContent
                        .fixedSize(horizontal: true, vertical: false)
                        .hidden()
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: AccountFeatureRowLeadingContentWidthKey.self,
                                    value: proxy.size.width
                                )
                            }
                        }
                }

            if let message = row.message, section != .other {
                rowMessage(message)
            }

            if row.action != nil {
                Image(systemName: "chevron.right")
                    .foregroundColor(.from(.infoColor, isDarkMode))
            }

            if let image = row.image {
                Spacer()

                Image(image)
                    .foregroundColor(.from(.infoColor, isDarkMode))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: AccountFeatureRowContentWidthKey.self,
                    value: proxy.size.width
                )
            }
        }
        .onPreferenceChange(AccountFeatureRowLeadingContentWidthKey.self) { width in
            leadingContentWidth = width
        }
        .onPreferenceChange(AccountFeatureRowContentWidthKey.self) { width in
            rowContentWidth = width
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var leadingContent: some View {
        HStack(spacing: 6) {
            if row.shouldShowExclamationIcon(accountStatus: accountStatus) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(row.shouldShowConfirmEmailBanner(accountStatus: accountStatus) ? .orangeYellow : .from(.iconColor, isDarkMode))
            }

            Text(row.title)
                .foregroundColor(.from(.titleColor, isDarkMode))
                .font(.medium(.callout))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private func rowMessage(_ message: String) -> some View {
        Text(message)
            .foregroundColor(messageColor(message))
            .font(.regular(.callout))
            .lineLimit(1)
            .truncationMode(.middle)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .opacity(showCopied ? 0.2 : 1)
            .overlay {
                if showCopied {
                    Text(TextsAsset.copied)
                        .font(.regular(.callout))
                        .foregroundColor(.from(.titleColor, isDarkMode))
                        .transition(.opacity)
                }
            }
            .onTapGesture {
                guard row.isCopyable else { return }
                UIPasteboard.general.string = message
                withAnimation { showCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showCopied = false }
                }
            }
    }

    private func messageColor(_ message: String) -> Color {
        if section != .plan {
            return .from(.infoColor, isDarkMode)
        }

        if message == TextsAsset.pro {
            return .actionGreen
        }

        if message == TextsAsset.Account.freeAccountDescription {
            return .from(.titleColor, isDarkMode)
        }

        return .infoGrey
    }
}

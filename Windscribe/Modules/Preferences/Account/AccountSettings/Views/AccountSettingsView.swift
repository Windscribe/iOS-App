//
//  AccountSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

struct AccountSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: AccountSettingsViewModelImpl

    @State private var inputText = ""
    @State private var dialog: AccountInputDialog?
    @State private var fallbackDialog: AccountInputDialog?
    @State private var isShowingEnterEmailView = false
    @State private var showUpgradeModal = false
    @State private var upgradePromoCode: String?
    @State private var hasLoaded = false
    @State private var showCustomLazyLoginAlert = false

    init(viewModel: any AccountSettingsViewModel) {
        guard let model = viewModel as? AccountSettingsViewModelImpl else {
            fatalError("AccountSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            if case let .loading(isFullScreen) = viewModel.loadingState, isFullScreen {
                MenuLoadingOverlayView(isDarkMode: $viewModel.isDarkMode, isFullScreen: true)
            } else {
                PreferencesBaseView(isDarkMode: $viewModel.isDarkMode, useHapticFeedback: false) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(viewModel.sections) { section in
                                AccountSectionView(
                                    isDarkMode: viewModel.isDarkMode,
                                    section: section,
                                    accountStatus: viewModel.accountEmailStatus,
                                    handleRowAction: viewModel.handleRowAction,
                                    presentDialog: { dialogType in
                                        presentDialog(for: dialogType)
                                    }
                                )

                                if section.type == .info, viewModel.shouldShowAddEmailButton {
                                    infoActionButtons()
                                }

                                if section.type == .plan {
                                    planActionButtons()
                                }
                            }
                        }
                        .onAppear {
                            if !hasLoaded {
                                viewModel.loadSession()
                                hasLoaded = true
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }

            if case let .loading(isFullScreen) = viewModel.loadingState, !isFullScreen {
                MenuLoadingOverlayView(isDarkMode: $viewModel.isDarkMode, isFullScreen: false)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showPasswordResetSuccess) {
            PasswordResetSuccessView(
                isDarkMode: viewModel.isDarkMode,
                onClose: {
                    viewModel.dismissPasswordResetSuccess()
                }
            )
        }
        .dynamicTypeSize(dynamicTypeRange)
        .navigationTitle(TextsAsset.Account.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alertMessage) { alert in
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
            if dialog == .password {
                SecureField(dialogPlaceHolder(dialog), text: $inputText)
            } else {
                TextField(dialogPlaceHolder(dialog), text: $inputText)
            }

            Button(TextsAsset.confirm) {
                handleConfirm(dialog: dialog, input: inputText)
            }

            Button(TextsAsset.cancel, role: .cancel) { }
        }, message: {
            Text(dialogDescription(dialog))
        })
        .id(dialog?.id)
        .sheet(item: $fallbackDialog) { dialog in
            MenuTextFieldDialogView(
                title: dialogTitle(dialog),
                description: dialogDescription(dialog),
                placeholder: dialogPlaceHolder(dialog),
                isSecure: dialog == .password,
                isLazyCode: dialog == .lazyLogin,
                onConfirm: { input in
                    handleConfirm(dialog: dialog, input: input)
                },
                onCancel: {
                    fallbackDialog = nil
                }
            )
        }
        .sheet(isPresented: $showUpgradeModal) {
            if let promoCode = upgradePromoCode {
                PlanUpgradeViewControllerWrapper(promoCode: promoCode, pcpID: nil)
                    .edgesIgnoringSafeArea(.all)
            } else {
                PlanUpgradeViewControllerWrapper()
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onChange(of: viewModel.showUpgradeWithPromo) { promoCode in
            if let promoCode = promoCode {
                upgradePromoCode = promoCode
                showUpgradeModal = true
                viewModel.showUpgradeWithPromo = nil
            }
        }
        .onAppear {
            viewModel.actionSelected()
        }
        .overlay(
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
                        isDarkMode: viewModel.isDarkMode,
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
        )
    }

    @ViewBuilder
    private func infoActionButtons() -> some View {
        Button(action: {
            isShowingEnterEmailView = true
        }, label: {
            Text(TextsAsset.Account.addEmailActionTitle)
                .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                .font(.medium(.callout))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(14)
                .background(Color.from(.backgroundColor, viewModel.isDarkMode))
                .cornerRadius(12)
                .padding(.horizontal, 16)
        })
        .background(
            NavigationLink(
                destination: Assembler.resolve(EnterEmailView.self),
                isActive: $isShowingEnterEmailView,
                label: { EmptyView() }
            )
            .hidden()
        )
    }

    @ViewBuilder
    private func planActionButtons() -> some View {
        VStack(spacing: 12) {
            // Button 1: Upgrade to Pro
            if viewModel.shouldShowUpgradeButton {
                Button(action: {
                    showUpgradeModal = true
                }, label: {
                    Text(TextsAsset.Account.upgradeToProActionTitle)
                        .foregroundColor(.actionBlue)
                        .font(.medium(.callout))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(14)
                        .background(Color.actionBlue.opacity(0.15))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                })
            }

            // Button 2: Delete Account
            if viewModel.shouldShowDeleteAccountButton {
                Button(action: {
                    presentDialog(for: .password)
                }, label: {
                    Text(TextsAsset.Account.cancelAccount)
                        .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                        .font(.medium(.callout))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(14)
                        .background(Color.from(.backgroundColor, viewModel.isDarkMode))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                })
            }

            // Button 3: Reset Password
            if viewModel.shouldShowResetPasswordButton && !viewModel.resetPasswordButtonHidden {
                Button(action: {
                    viewModel.resetPassword()
                }, label: {
                    Text(TextsAsset.Account.resetPasswordActionTitle)
                        .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                        .font(.medium(.callout))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(14)
                        .background(Color.from(.backgroundColor, viewModel.isDarkMode))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                })
            }
        }
    }

    private func handleConfirm(dialog selectedDialog: AccountInputDialog?, input: String) {
        switch selectedDialog {
        case .password:
            viewModel.confirmCancelAccount(password: input)
        case .lazyLogin:
            viewModel.verifyLazyLogin(code: input)
        case .none:
            break
        }

        dialog = nil
        fallbackDialog = nil
    }

    private func dialogTitle(_ dialog: AccountInputDialog?) -> String {
        guard let dialog = dialog else {
            return TextsAsset.Account.defaultDialogTitle
        }

        switch dialog {
        case .password:
            return TextsAsset.Account.cancelAccount
        case .lazyLogin:
            return TextsAsset.Account.loginCodeTitle
        }
    }

    private func dialogDescription(_ dialog: AccountInputDialog?) -> String {
        guard let dialog = dialog else {
            return TextsAsset.Account.defaultDialogMessage
        }

        switch dialog {
        case .password:
            return TextsAsset.Account.deleteAccountMessage
        case .lazyLogin:
            return TextsAsset.Account.lazyLoginDescription
        }
    }

    private func dialogPlaceHolder(_ dialog: AccountInputDialog?) -> String {
        guard let dialog = dialog else {
            return TextsAsset.Account.defaultDialogTitle
        }

        switch dialog {
        case .password:
            return TextsAsset.Account.accountPasswordTitle
        case .lazyLogin:
            return TextsAsset.Account.loginCodeTitle
        }
    }

    private func presentDialog(for type: AccountInputDialog) {
        inputText = ""
        if type == .lazyLogin {
            showCustomLazyLoginAlert = true
        } else if #available(iOS 16, *) {
            dialog = type
        } else {
            fallbackDialog = type
        }
    }
}

struct AccountSectionView: View {
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
                ForEach(section.items.indices, id: \.self) { index in
                    let row = section.items[index]
                    VStack(spacing: 12) {
                        accountRow(
                            row: row,
                            sectionType:
                                section.type,
                            showDivider: false,
                            accountStatus: accountStatus)
                    }
                    .background(Color.from(.backgroundColor, isDarkMode))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }

            } else {
                VStack(spacing: 0) {
                    ForEach(section.items.indices, id: \.self) { index in
                        let row = section.items[index]
                        let showDivider = index < section.items.count - 1

                        accountRow(
                            row: row,
                            sectionType:
                                section.type,
                            showDivider: showDivider,
                            accountStatus: accountStatus)
                    }
                }
                .background(Color.from(.backgroundColor, isDarkMode))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }

            if accountStatus == .unverified {
                Button(action: {
                    handleRowAction(.resendEmail)
                }, label: {
                    Text(TextsAsset.EmailView.resendEmail)
                        .foregroundColor(.from(.titleColor, isDarkMode))
                        .font(.medium(.callout))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(14)
                        .background(Color.from(.backgroundColor, isDarkMode))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                })
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func accountRow(
        row: AccountRowModel,
        sectionType: AccountSectionType,
        showDivider: Bool,
        accountStatus: AccountEmailStatusType) -> some View {
            AccountRowView(
                isDarkMode: isDarkMode,
                row: row,
                section: sectionType,
                showDivider: showDivider,
                accountStatus: accountStatus
            ) { action in
                switch action {
                case .openLazyLogin:
                    presentDialog(.lazyLogin)
                case .cancelAccount:
                    presentDialog(.password)
                case .resendEmail:
                    handleRowAction(action)
                default: break
                }
            }
        }
}

private struct AccountRowLeadingContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct AccountRowContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct AccountRowView: View {
    let isDarkMode: Bool
    let row: AccountRowModel
    let section: AccountSectionType
    let showDivider: Bool
    let accountStatus: AccountEmailStatusType
    let actionHandler: (AccountRowAction) -> Void

    @State private var showCopied = false
    @State private var leadingContentWidth: CGFloat = 0
    @State private var rowContentWidth: CGFloat = 0

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

    var body: some View {
        VStack(spacing: 0) {
            let maxLeadingWidth = rowContentWidth / 2
            let leadingWidth = rowContentWidth > 0 ? min(leadingContentWidth, maxLeadingWidth) : leadingContentWidth

            HStack(alignment: .top, spacing: 6) {
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
                                        key: AccountRowLeadingContentWidthKey.self,
                                        value: proxy.size.width
                                    )
                                }
                            }
                    }

                if let message = row.message, section != .other {
                    Text(message)
                            .foregroundColor(section == .plan
                                             ? (message == TextsAsset.pro ? .actionGreen : (message == TextsAsset.Account.freeAccountDescription) ? .from(.titleColor, isDarkMode) : .infoGrey)
                                             : .from(.infoColor, isDarkMode))
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
                        key: AccountRowContentWidthKey.self,
                        value: proxy.size.width
                    )
                }
            }
            .onPreferenceChange(AccountRowLeadingContentWidthKey.self) { width in
                leadingContentWidth = width
            }
            .onPreferenceChange(AccountRowContentWidthKey.self) { width in
                rowContentWidth = width
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

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
}

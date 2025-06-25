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
    @State private var hasLoaded = false

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
                PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
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

                                if section.type == .plan, viewModel.shouldShowPlanActionButtons {
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
            get: { dialog != nil },
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
                onConfirm: { input in
                    handleConfirm(dialog: dialog, input: input)
                },
                onCancel: {
                    fallbackDialog = nil
                }
            )
        }
        .sheet(isPresented: $showUpgradeModal) {
            PlanUpgradeViewControllerWrapper()
                .edgesIgnoringSafeArea(.all)
        }
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
            Button(action: {
                showUpgradeModal = true
            }, label: {
                Text(TextsAsset.Account.upgradeToProActionTitle)
                    .foregroundColor(.actionGreen)
                    .font(.medium(.callout))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(14)
                    .background(Color.actionGreen.opacity(0.20))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
            })

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
    }

    private func handleConfirm(dialog selectedDialog: AccountInputDialog?, input: String) {
        switch selectedDialog {
        case .voucher:
            viewModel.verifyVoucher(code: input)
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
        case .voucher:
            return TextsAsset.Account.voucherCodeTitle
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
        case .voucher:
            return TextsAsset.Account.voucherCodeDescription
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
        case .voucher:
            return TextsAsset.Account.voucherCodeTitle
        case .password:
            return TextsAsset.Account.accountPasswordTitle
        case .lazyLogin:
            return TextsAsset.Account.loginCodeTitle
        }
    }

    private func presentDialog(for type: AccountInputDialog) {
        inputText = ""
        if #available(iOS 16, *) {
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
                .font(.caption)
                .foregroundColor(.from(.infoColor, isDarkMode))
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
                case .openVoucher:
                    presentDialog(.voucher)
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

struct AccountRowView: View {
    let isDarkMode: Bool
    let row: AccountRowModel
    let section: AccountSectionType
    let showDivider: Bool
    let accountStatus: AccountEmailStatusType
    let actionHandler: (AccountRowAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    if row.shouldShowExclamationIcon(accountStatus: accountStatus) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(row.shouldShowConfirmEmailBanner(accountStatus: accountStatus) ? .orangeYellow : .from(.iconColor, isDarkMode))
                    }

                    Text(row.title)
                        .foregroundColor(.from(.titleColor, isDarkMode))
                        .font(.medium(.callout))
                }

                Spacer()

                if let message = row.message, section != .other {
                    Text(message)
                        .foregroundColor(section == .plan
                                         ? (message == TextsAsset.pro ? .actionGreen : (message == TextsAsset.Account.freeAccountDescription) ? .from(.titleColor, isDarkMode) : .infoGrey)
                                         : .from(.infoColor, isDarkMode))
                        .font(.regular(.callout))

                }

                if row.action != nil {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.from(.infoColor, isDarkMode))
                }
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
                    .background(Color.from(.backgroundColor, isDarkMode))
                    .cornerRadius(10)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .padding(.bottom, 8)
            }

            if row.shouldShowConfirmEmailBanner(accountStatus: accountStatus) {
                Button(action: {
                    actionHandler(.resendEmail)
                }, label: {
                    HStack {
                        Text(TextsAsset.EmailView.infoPro)
                            .foregroundColor(.from(.dark, isDarkMode))
                            .font(.medium(.footnote))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(TextsAsset.Account.resend)
                            .font(.bold(.footnote))
                            .foregroundColor(.from(.dark, isDarkMode))
                    }
                    .padding(12)
                    .background(Color.orangeYellow)
                    .cornerRadius(8)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
                })
                .buttonStyle(PlainButtonStyle())
            }

            if showDivider {
                Divider()
                    .background(Color.from(.separatorColor, isDarkMode))
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

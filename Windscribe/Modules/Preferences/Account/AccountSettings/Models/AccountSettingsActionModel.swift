//
//  AccountSettingsActionModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-22.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

enum AccountRowType: Hashable {
    case textRow(title: String, value: String)
    case confirmEmail(email: String)
    case button(title: String)
    case navigation(title: String, subtitle: String?)
}

enum AccountSectionType: String {
    case info
    case plan
    case other

    var title: String {
        switch self {
        case .info: return TextsAsset.Account.info
        case .plan: return TextsAsset.Account.plan
        case .other: return TextsAsset.Account.other
        }
    }
}

struct AccountRowModel: Identifiable, Hashable {
    var id = UUID()

    let type: AccountRowType
    let action: AccountRowAction?

    var title: String {
        switch type {
        case .textRow(let title, _):
            return title
        case .confirmEmail:
            return TextsAsset.email
        case .button(let title):
            return title
        case .navigation(let title, _):
            return title
        }
    }

    var message: String? {
        switch type {
        case .textRow(_, let value):
            return value
        case .confirmEmail(let email):
            return email
        case .navigation(_, let subtitle):
            return subtitle
        default: return nil
        }
    }

    func descriptionText(accountStatus: AccountEmailStatusType) -> String? {
        if title.lowercased() == TextsAsset.email && accountStatus == .missing {
            return TextsAsset.Account.includeEmailDesciption
        }
        return nil
    }

    func needsWarningIcon(accountStatus: AccountEmailStatusType) -> Bool {
        title.lowercased() == TextsAsset.email && (accountStatus == .missing || accountStatus == .unverified)
    }

    func shouldShowConfirmEmailBanner(accountStatus: AccountEmailStatusType) -> Bool {
        title.lowercased() == TextsAsset.email && accountStatus == .unverified
    }
}

struct AccountSectionModel: Identifiable, Hashable {
    let id = UUID()
    let type: AccountSectionType
    let items: [AccountRowModel]
}

enum AccountRowAction: Hashable {
    case resendEmail
    case cancelAccount
    case openVoucher
    case openLazyLogin
    case upgradeToPro
}

enum AccountDialogType: String, Identifiable, CaseIterable {
    case enterPassword
    case enterVoucher
    case enterLazyLogin

    var id: String { rawValue }
}

enum AccountEmailStatusType {
    case verified
    case missing
    case unverified
}

struct AccountSettingsAlertContent: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let buttonText: String
}

enum AccountInputDialog: String, Identifiable, CaseIterable {
    case voucher
    case password
    case lazyLogin

    var id: String { rawValue }
}

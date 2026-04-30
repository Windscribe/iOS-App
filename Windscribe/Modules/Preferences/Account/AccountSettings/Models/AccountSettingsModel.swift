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
    case textImageRow(title: String, imageName: String)
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
        case .plan: return TextsAsset.Account.planInfo
        case .other: return TextsAsset.Account.other
        }
    }
}

struct AccountRowModel: Identifiable, Equatable {
    let id = UUID()

    let type: AccountRowType
    let action: AccountRowAction?
    let isCopyable: Bool

    init(type: AccountRowType, action: AccountRowAction?, copyable: Bool = false) {
        self.type = type
        self.action = action
        self.isCopyable = copyable
    }

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
        case .textImageRow(title: let title, _):
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

    var image: String? {
        switch type {
        case .textImageRow(_, imageName: let image):
            return image
        default: return nil
        }
    }

    func descriptionText(accountStatus: AccountEmailStatusType) -> String? {
        if title.lowercased() == TextsAsset.email.lowercased() && accountStatus == .missing {
            return TextsAsset.Account.includeEmailDesciption
        }
        return nil
    }

    func shouldShowConfirmEmailBanner(accountStatus: AccountEmailStatusType) -> Bool {
        title.lowercased() == TextsAsset.email.lowercased()  && accountStatus == .unverified
    }

    func shouldShowExclamationIcon(accountStatus: AccountEmailStatusType) -> Bool {
        title.lowercased() == TextsAsset.email.lowercased()  && accountStatus != .verified
    }
}

struct AccountSectionModel: Identifiable, Equatable {
    let id = UUID()
    let type: AccountSectionType
    let items: [AccountRowModel]
}

enum AccountRowAction: Hashable {
    case resendEmail
    case cancelAccount
    case openLazyLogin
    case upgradeToPro
}

enum AccountDialogType: String, Identifiable, CaseIterable {
    case enterPassword
    case enterLazyLogin

    var id: String { rawValue }
}

enum AccountEmailStatusType {
    case verified
    case missing
    case unverified
    case unknown
}

struct AccountSettingsAlertContent: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let buttonText: String
}

enum AccountInputDialog: String, Identifiable, CaseIterable {
    case password
    case lazyLogin

    var id: String { rawValue }
}

enum AccountState: Equatable {
    case initial
    case loading(isFullScreen: Bool)
    case error(String)
    case success
}

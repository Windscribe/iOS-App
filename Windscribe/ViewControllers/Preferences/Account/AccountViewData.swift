//
//    AccountViewData.swift
//    Windscribe
//
//    Created by Thomas on 20/05/2022.
//    Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import RxSwift

enum AccountItemCell {
    private var  localDatabase: LocalDatabase {
        return Assembler.resolve(LocalDatabase.self)
    }

    private var session: Session? { localDatabase.getSessionSync() }

    var isProUser: Bool {
        if let session = session {
            return session.isUserPro
        } else {
            return false
        }
    }

    var billingPlanId: Int {
        if let session = session {
            return session.billingPlanId
        } else {
            return 0
        }
    }

    case username
    case email
    case emailPro
    case planType
    case expiredDate
    case dateLeft
    case confirmEmail
    case emailEmpty
    case cancelAccount
    
    var isUpgradeButton: Bool {
        return self == .planType && needUpgradeAccount
    }
    
    var hasAction: Bool {
        return [AccountItemCell.cancelAccount, AccountItemCell.confirmEmail].contains(self) || isUpgradeButton
    }

    var title: String? {
        guard let session = session else {
            return nil
        }

        switch self {
        case .username:
            return TextsAsset.username
        case .email:
            return TextsAsset.email
        case .planType:
            if session.isUserPro {
                return TextsAsset.UpgradeView.unlimitedData
            } else {
                return "\(session.getDataMax())/\(TextsAsset.UpgradeView.month)"
            }
        case .expiredDate:
            if session.isUserPro {
                return TextsAsset.Account.expiryDate
            } else {
                return TextsAsset.Account.resetDate
            }
        case .dateLeft:
            return TextsAsset.Account.dataLeft
        case .confirmEmail:
            //                        return TextsAsset.Account.confirmYourEmail
            return TextsAsset.email
        case .emailEmpty:
            if session.isUserPro {
                return TextsAsset.Account.addEmailDescriptionPro
            }
            return TextsAsset.Account.addEmailDescription
        case .cancelAccount:
            return TextsAsset.Account.cancelAccount
        case .emailPro:
            return TextsAsset.email
        }
    }

    private var themeManager: ThemeManager {
        return Assembler.resolve(ThemeManager.self)
    }

    var value: NSAttributedString? {
        guard let session = session else {
            return nil
        }
        switch self {
        case .username:
            return NSAttributedString(string: session.username, attributes: getDeviceFontAttributes())
        case .email, .emailPro:
            if session.email.isEmpty {
                return NSAttributedString(string: TextsAsset.Account.addEmail,
                                          attributes: getDeviceFontAttributes(isFullColor: false))
            }
            return NSAttributedString(string: session.email,
                                      attributes: getDeviceFontAttributes(isFullColor: false))
        case .planType:
            if session.isUserPro {
                if UIDevice.current.isTV {
                    return TextsAsset.pro.withIcon(icon: UIImage(named: ImagesAsset.prefProIconGrey)!.withTintColor(.whiteWithOpacity(opacity: 0.5), renderingMode: .alwaysTemplate),
                                                                         bounds: CGRect(x: 0, y: -2.5, width: 42, height: 42),
                                                                         textColor: UIColor.seaGreen)
                }
                else if themeManager.getIsDarkTheme() {
                    return TextsAsset.pro.withIcon(icon: UIImage(named: ImagesAsset.prefProIconGreen)!,
                                                   bounds: CGRect(x: 0, y: 0, width: 16, height: 16),
                                                   textColor: UIColor.seaGreen)
                } else {
                    return TextsAsset.pro.withIcon(icon: UIImage(named: ImagesAsset.prefProIconBlue)!,
                                                   bounds: CGRect(x: 0, y: -2.5, width: 16, height: 16),
                                                   textColor: UIColor.brightBlue)
                }
            } else {
                return NSAttributedString(string: TextsAsset.Account.upgrade,
                                          attributes: getDeviceFontAttributes(isFullColor: false))
            }
        case .expiredDate:
            if session.isPremium {
                return NSAttributedString(string: session.premiumExpiryDate,
                                          attributes: getDeviceFontAttributes())
            } else {
                return NSAttributedString(string: session.getNextReset(),
                                          attributes: getDeviceFontAttributes())
            }
        case .dateLeft:
            return NSAttributedString(string: session.getDataLeft(),
                                      attributes: getDeviceFontAttributes(isFullColor: false))
        case .emailEmpty:
            return NSAttributedString(string: TextsAsset.Account.addEmail,
                                      attributes: getDeviceFontAttributes())
        case .confirmEmail:
            if session.email.isEmpty {
                return NSAttributedString(string: TextsAsset.Account.resend,
                                          attributes: getDeviceFontAttributes())
            }
            return NSAttributedString(string: session.email,
                                      attributes: getDeviceFontAttributes())
        default:
            return nil
        }
    }

    private func getDeviceFontAttributes(isFullColor: Bool = false) -> [NSAttributedString.Key: Any] {
        if UIDevice.current.isTV {
            return [.font: UIFont.regular(size: 42), .foregroundColor: UIColor.white.withAlphaComponent(isFullColor ? 1 : 0.5)]
        }
        return [.font: UIFont.text(size: 16)]
    }

    var needUpgradeAccount: Bool {
        guard let session = session else {
            return false
        }
        if session.isUserPro || session.isPremium || session.billingPlanId == -9 {
            return false
        }
        return true
    }

    var needAddEmail: Bool {
        return session?.email.isEmpty ?? false
    }
}

enum AccountSectionItem {
    private var  localDatabase: LocalDatabase {
        return Assembler.resolve(LocalDatabase.self)
    }

    private var session: Session? { localDatabase.getSessionSync() }

    var isProUser: Bool {
        if let session = session {
            return session.isUserPro
        } else {
            return false
        }
    }

    case info
    case plan

    var items: [AccountItemCell] {
        switch self {
        case .info:
            return makeInfoItems()
        case .plan:
            return makePlanItems()
        }
    }

    var title: String {
        switch self {
        case .info:
            return TextsAsset.Account.info
        case .plan:
            return TextsAsset.Account.plan
        }
    }

    private func makeInfoItems() -> [AccountItemCell] {
        guard let session = session else {
            return []
        }

        if session.email.isEmpty {
            return [.username, .emailEmpty]
        }
        if session.email.isEmpty == false,
           session.emailStatus == false {
            return [.username, .confirmEmail]
        }
        if session.isUserPro {
            return [.username, .emailPro]
        }
        return [.username, .email]
    }

    private func makePlanItems() -> [AccountItemCell] {
        if let session = session, session.isUserPro {
            return [.planType, .expiredDate, .cancelAccount]
        }
        return [.planType, .expiredDate, .dateLeft, .cancelAccount]
    }
}

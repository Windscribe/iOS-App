//
//  PreferencesAction.swift
//  Windscribe
//
//  Created by Andre Fonseca on 29/06/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI


enum PreferencesAction: Int, Equatable {
    struct Display {
        let title: String
        let icon: String?
        let backgroundColor: Color
        let textColor: Color
    }

    case email = 0
    case emailGet10GB
    case setupAccountAndLogin
    case setupAccount
    case confirmEmail
    case login

    var id: Int {
        self.rawValue
    }

    func getActionDisplay(isDarkMode: Bool) -> PreferencesAction.Display {
        switch self {
        case .email:
            PreferencesAction.Display(title: TextsAsset.addEmail,
                                     icon: ImagesAsset.warningBlack,
                                     backgroundColor: .unconfirmedYellow,
                                     textColor: .midnight)
        case .emailGet10GB:
            PreferencesAction.Display(title: "\(TextsAsset.addEmail) (\(TextsAsset.get10GbAMonth))",
                                     icon: ImagesAsset.warningBlack,
                                     backgroundColor: .unconfirmedYellow,
                                     textColor: .midnight)
        case .setupAccount, .setupAccountAndLogin:
            PreferencesAction.Display(title: TextsAsset.setupAccount,
                                     icon: ImagesAsset.warningBlack,
                                     backgroundColor: .unconfirmedYellow,
                                     textColor: .midnight)
        case .confirmEmail:
            PreferencesAction.Display(title: TextsAsset.EmailView.confirmEmail,
                                     icon: ImagesAsset.warningBlack,
                                     backgroundColor: .unconfirmedYellow,
                                     textColor: .midnight)
        case .login:
            PreferencesAction.Display(title: TextsAsset.login,
                                     icon: ImagesAsset.warningBlack,
                                     backgroundColor: .from(.actionBackgroundColor, isDarkMode),
                                     textColor: .from(.titleColor, isDarkMode))
        }
    }
}

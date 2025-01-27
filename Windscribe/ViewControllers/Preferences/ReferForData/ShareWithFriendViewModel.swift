//
//  ShareWithFriendViewModel.swift
//  Windscribe
//
//  Created by Thomas on 20/09/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ShareWithFriendViewModelType {
    var isDarkMode: BehaviorSubject<Bool> { get }
    var referFriendManager: ReferAndShareManagerV2 { get }
    var themeManager: ThemeManager { get }
    var appStoreLink: String { get }
    var inviteMessage: String { get }
}

class ShareWithFriendViewModel: ShareWithFriendViewModelType {
    let themeManager: ThemeManager, sessionManager: SessionManagerV2, referFriendManager: ReferAndShareManagerV2
    let isDarkMode: BehaviorSubject<Bool>

    init(themeManager: ThemeManager, sessionManager: SessionManagerV2, referFriendManager: ReferAndShareManagerV2) {
        self.themeManager = themeManager
        self.sessionManager = sessionManager
        self.referFriendManager = referFriendManager
        isDarkMode = themeManager.darkTheme
    }

    private var username: String {
        return sessionManager.session?.username ?? "User"
    }

    private(set) var appStoreLink = "https://apps.apple.com/us/app/windscribe-vpn/id1129435228"
    var inviteMessage: String {
        return "\(username) \(TextsAsset.Refer.inviteMessage)"
    }
}

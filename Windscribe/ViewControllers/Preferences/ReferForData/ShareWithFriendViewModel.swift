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
    var lookAndFeelRepo: LookAndFeelRepositoryType { get }
    var appStoreLink: String { get }
    var inviteMessage: String { get }
}

class ShareWithFriendViewModel: ShareWithFriendViewModelType {
    let lookAndFeelRepo: LookAndFeelRepositoryType, sessionManager: SessionManagerV2, referFriendManager: ReferAndShareManagerV2
    let isDarkMode: BehaviorSubject<Bool>

    init(lookAndFeelRepo: LookAndFeelRepositoryType, sessionManager: SessionManagerV2, referFriendManager: ReferAndShareManagerV2) {
        self.lookAndFeelRepo = lookAndFeelRepo
        self.sessionManager = sessionManager
        self.referFriendManager = referFriendManager
        isDarkMode = lookAndFeelRepo.isDarkModeSubject
    }

    private var username: String {
        return sessionManager.session?.username ?? "User"
    }

    private(set) var appStoreLink = "https://apps.apple.com/us/app/windscribe-vpn/id1129435228"
    var inviteMessage: String {
        return "\(username) \(TextsAsset.Refer.inviteMessage)"
    }
}

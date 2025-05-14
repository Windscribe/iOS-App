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
    var lookAndFeelRepository: LookAndFeelRepositoryType { get }
    var appStoreLink: String { get }
    var inviteMessage: String { get }
}

class ShareWithFriendViewModel: ShareWithFriendViewModelType {
    let lookAndFeelRepository: LookAndFeelRepositoryType, sessionManager: SessionManagerV2, referFriendManager: ReferAndShareManagerV2
    let isDarkMode: BehaviorSubject<Bool>

    init(lookAndFeelRepository: LookAndFeelRepositoryType, sessionManager: SessionManagerV2, referFriendManager: ReferAndShareManagerV2) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.sessionManager = sessionManager
        self.referFriendManager = referFriendManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
    }

    private var username: String {
        return sessionManager.session?.username ?? "User"
    }

    private(set) var appStoreLink = "https://apps.apple.com/us/app/windscribe-vpn/id1129435228"
    var inviteMessage: String {
        return "\(username) \(TextsAsset.Refer.inviteMessage)"
    }
}

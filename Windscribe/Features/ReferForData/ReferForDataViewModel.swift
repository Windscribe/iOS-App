//
//  ReferForDataViewModel.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-10.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Observation

@available(iOS 17.0, *)
@Observable
@MainActor
final class ReferForDataViewModel {

    // MARK: - State
    var showShareSheet = false

    let appStoreLink = Links.appStoreLink

    var inviteMessage: String {
        let username = sessionProviding.session?.username ?? TextsAsset.Refer.usernamePlaceholder
        return "\(username) \(TextsAsset.Refer.inviteMessage)"
    }

    // MARK: - Dependencies

    private let sessionProviding: any SessionProviding
    private let referAndSharing: any ReferAndSharing

    // MARK: - Init

    init(sessionProviding: any SessionProviding, referAndSharing: any ReferAndSharing) {
        self.sessionProviding = sessionProviding
        self.referAndSharing = referAndSharing
    }

    // MARK: - Actions

    func shareInviteLinkSelected() {
        referAndSharing.setShowedShareDialog(showed: true)
        showShareSheet = true
    }
}

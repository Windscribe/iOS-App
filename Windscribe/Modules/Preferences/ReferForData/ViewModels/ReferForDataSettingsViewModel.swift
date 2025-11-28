//
//  ReferForDataSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol ReferForDataSettingsViewModel: ObservableObject {
    var isDarkMode: Bool { get }
    var appStoreLink: String { get }
    var inviteMessage: String { get }
    func markShareDialogShown()
}

final class ReferForDataSettingsViewModelImpl: ReferForDataSettingsViewModel {
    @Published var isDarkMode: Bool = false

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let userSessionRepository: UserSessionRepository
    private let referFriendManager: ReferAndShareManager
    private let logger: FileLogger
    private var cancellables = Set<AnyCancellable>()

    var appStoreLink = Links.appStoreLink

    var inviteMessage: String {
        let username = userSessionRepository.sessionModel?.username ?? TextsAsset.Refer.usernamePlaceholder
        return "\(username) \(TextsAsset.Refer.inviteMessage)"
    }

    init(
        lookAndFeelRepository: LookAndFeelRepositoryType,
        userSessionRepository: UserSessionRepository,
        referFriendManager: ReferAndShareManager,
        logger: FileLogger
    ) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.userSessionRepository = userSessionRepository
        self.referFriendManager = referFriendManager
        self.logger = logger

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isDarkMode = $0
            }
            .store(in: &cancellables)
    }

    func markShareDialogShown() {
        referFriendManager.setShowedShareDialog(showed: true)
    }
}

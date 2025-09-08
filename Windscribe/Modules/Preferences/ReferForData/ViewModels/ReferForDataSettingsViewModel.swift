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
    private let sessionManager: SessionManaging
    private let referFriendManager: ReferAndShareManager
    private let logger: FileLogger
    private var cancellables = Set<AnyCancellable>()

    var appStoreLink = Links.appStoreLink

    var inviteMessage: String {
        let username = sessionManager.session?.username ?? TextsAsset.Refer.usernamePlaceholder
        return "\(username) \(TextsAsset.Refer.inviteMessage)"
    }

    init(
        lookAndFeelRepository: LookAndFeelRepositoryType,
        sessionManager: SessionManaging,
        referFriendManager: ReferAndShareManager,
        logger: FileLogger
    ) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.sessionManager = sessionManager
        self.referFriendManager = referFriendManager
        self.logger = logger

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.logger.logE("ReferFriendDataViewModel", "Dark mode binding error: \(error)")
                    }
                },
                receiveValue: { [weak self] in
                    self?.isDarkMode = $0
                }
            )
            .store(in: &cancellables)
    }

    func markShareDialogShown() {
        referFriendManager.setShowedShareDialog(showed: true)
    }
}

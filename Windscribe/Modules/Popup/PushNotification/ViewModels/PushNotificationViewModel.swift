//
//  PushNotificationViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-21.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol PushNotificationViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var shouldDismiss: Bool { get set }

    func enableNotifications()
    func cancel()
}

final class PushNotificationViewModelImpl: PushNotificationViewModel {
    @Published var isDarkMode: Bool = false
    @Published var shouldDismiss: Bool = false

    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let pushNotificationsManager: PushNotificationManager
    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         pushNotificationsManager: PushNotificationManager) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.pushNotificationsManager = pushNotificationsManager

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

    func enableNotifications() {
        logger.logD("PushNotificationViewModel", "Asking for push notification permission.")
        pushNotificationsManager.askForPushNotificationPermission()
        shouldDismiss = true
    }

    func cancel() {
        logger.logD("PushNotificationViewModel", "Push notification permission cancelled.")
        shouldDismiss = true
    }
}

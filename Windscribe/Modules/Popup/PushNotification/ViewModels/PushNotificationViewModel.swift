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
    private let pushNotificationsManager: PushNotificationManagerV2
    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         pushNotificationsManager: PushNotificationManagerV2) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.pushNotificationsManager = pushNotificationsManager

        bind()
    }

    private func bind() {
        // Theme subscription using RxSwift bridge
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("PushNotificationViewModel", "Theme subscription error: \(error)")
                }
            }, receiveValue: { [weak self] in
                self?.isDarkMode = $0
            })
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

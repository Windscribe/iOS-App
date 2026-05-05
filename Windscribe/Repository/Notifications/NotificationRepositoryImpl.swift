//
//  NotificationRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

class NotificationRepositoryImpl: NotificationRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let pushNotificationsManager: PushNotificationManager

    let notices = CurrentValueSubject<[NoticeModel], Never>([])
    let readNotices = CurrentValueSubject<[Int], Never>([])
    private var cancellables = Set<AnyCancellable>()

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger, pushNotificationsManager: PushNotificationManager) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
        self.pushNotificationsManager = pushNotificationsManager

        // Subscribe to database notifications observable for reactive updates
        localDatabase.getNotificationsPublisher()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.logger.logE("NotificationRepositoryImpl", "Failed to observe notifications: \(error)")
                    }
                },
                receiveValue: { [weak self] notifications in
                    self?.notices.send(notifications)
                }
            )
            .store(in: &cancellables)

        localDatabase.getReadNoticesPublisher()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.logger.logE("NotificationRepositoryImpl", "Failed to observe read notices: \(error)")
                    }
                },
                receiveValue: { [weak self] notifications in
                    self?.readNotices.send(notifications)
                }
            )
            .store(in: &cancellables)
    }

    @MainActor
    func getUpdatedNotifications() async throws -> [NoticeModel] {
        let pcpid = pushNotificationsManager.notification.value?.pcpid ?? ""

        if !pcpid.isEmpty {
            logger.logD("NotificationRepository", "Adding pcpid ID: \(pcpid) to notifications request.")
        }

        let result = try await apiManager.getNotifications(pcpid: pcpid)
        let notificationsArray = Array(result.notices)

        // Save to database - this will trigger the reactive publisher chain
        localDatabase.saveNotifications(notifications: notificationsArray.map { $0.getModel() })

        return notificationsArray.map { $0.getModel() }
    }

    func loadNotifications() async {
        do {
            // Fetch and save to database
            // The reactive chain (database publisher → notices subject) will automatically update subscribers
            _ = try await getUpdatedNotifications()
        } catch {
            logger.logE("NotificationRepository", "Failed to load notifications: \(error)")
        }
    }

    func readNotice(with id: Int) {
        var readNotifications = localDatabase.getReadNotices() ?? []
        guard !readNotifications.contains(id) else {
            return
        }
        readNotifications.append(id)
        localDatabase.saveReadNotices(readNotices: readNotifications)
    }
}

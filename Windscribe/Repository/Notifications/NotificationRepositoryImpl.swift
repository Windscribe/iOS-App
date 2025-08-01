//
//  NotificationRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class NotificationRepositoryImpl: NotificationRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let pushNotificationsManager: PushNotificationManagerV2
    private let disposeBag = DisposeBag()
    let notices = BehaviorSubject<[Notice]>(value: [])

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger, pushNotificationsManager: PushNotificationManagerV2) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
        self.pushNotificationsManager = pushNotificationsManager
    }

    func getUpdatedNotifications() -> Single<[Notice]> {
        let pcpid = (try? pushNotificationsManager.notification.value()?.pcpid) ?? ""

        if !pcpid.isEmpty {
            logger.logD("NotificationRepository", "Adding pcpid ID: \(pcpid) to notifications request.")
        }

        return apiManager.getNotifications(pcpid: pcpid).map {
            self.localDatabase.saveNotifications(notifications: Array($0.notices))
            return Array($0.notices)
        }.flatMap { notifications in
            Single.just(notifications)
        }
    }

    func loadNotifications() {
        getUpdatedNotifications().subscribe(onSuccess: { notices in
            self.notices.onNext(notices)
        }).disposed(by: disposeBag)
    }
}

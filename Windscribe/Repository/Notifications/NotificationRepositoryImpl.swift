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

    func getUpdatedNotifications(pcpid: String) -> Single<[Notice]> {
        logger.logD(self, "Getting notifications from API.")
        return apiManager.getNotifications(pcpid: pcpid).map {
            self.localDatabase.saveNotifications(notifications: $0.notices.toArray())
            return $0.notices.toArray()
        }.flatMap { notifications in
            Single.just(notifications)
        }
    }

    func loadNotifications() {
        let pcpId = (try? pushNotificationsManager.notification.value()?.pcpid) ?? ""
        if !pcpId.isEmpty {
            logger.logD(self, "Adding pcpid ID: \(pcpId) to notifications request.")
        }
        getUpdatedNotifications(pcpid: pcpId).subscribe(onSuccess: { notices in
            self.notices.onNext(notices)
        }).disposed(by: disposeBag)
    }
}

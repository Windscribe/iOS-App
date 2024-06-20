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
    private let disposeBag = DisposeBag()
    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
    }

    func getUpdatedNotifications(pcpid: String) -> Single<[Notice]> {
        logger.logD(self, "Getting notifications from API.")
        return self.apiManager.getNotifications(pcpid: pcpid).map {
            self.localDatabase.saveNotifications(notifications: $0.notices.toArray())
            return $0.notices.toArray()
        }.flatMap { notifications in
            return Single.just(notifications)
        }
    }
}

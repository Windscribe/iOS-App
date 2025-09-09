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
    private let pushNotificationsManager: PushNotificationManager
    private let disposeBag = DisposeBag()
    let notices = BehaviorSubject<[Notice]>(value: [])

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger, pushNotificationsManager: PushNotificationManager) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
        self.pushNotificationsManager = pushNotificationsManager
    }

    func getUpdatedNotifications() -> Single<[Notice]> {
        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.failure(Errors.validationFailure))
                    return
                }

                let pcpid = self.pushNotificationsManager.notification.value?.pcpid ?? ""

                if !pcpid.isEmpty {
                    self.logger.logD("NotificationRepository", "Adding pcpid ID: \(pcpid) to notifications request.")
                }

                do {
                    let result = try await self.apiManager.getNotifications(pcpid: pcpid)
                    await MainActor.run {
                        self.localDatabase.saveNotifications(notifications: Array(result.notices))
                        single(.success(Array(result.notices)))
                    }
                } catch {
                    await MainActor.run {
                        single(.failure(error))
                    }
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func loadNotifications() {
        getUpdatedNotifications().subscribe(onSuccess: { notices in
            self.notices.onNext(notices)
        }).disposed(by: disposeBag)
    }
}

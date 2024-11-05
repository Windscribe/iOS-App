//
//  NewsFeedModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 09/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

import RxCocoa
import RxSwift

protocol NewsFeedModelType {
    var newsSections: BehaviorRelay<[NewsSection]> { get }
    func didTapNotice(at index: Int)
}

class NewsFeedModel: NewsFeedModelType {
    // MARK: - Dependencies

    let notificationRepository: NotificationRepository
    let localDatabase: LocalDatabase
    let sessionManager: SessionManagerV2

    let disposeBag = DisposeBag()
    let newsSections = BehaviorRelay<[NewsSection]>(value: [])

    init(notificationRepository: NotificationRepository, localDatabase: LocalDatabase, sessionManager: SessionManagerV2) {
        self.notificationRepository = notificationRepository
        self.localDatabase = localDatabase
        self.sessionManager = sessionManager
        load()
    }

    private func load() {
        Observable.combineLatest(localDatabase.getNotificationsObservable(), localDatabase.getReadNoticesObservable().take(1))
            .filter { $0.0.filter { $0.isInvalidated }.count == 0 && $0.1.filter { $0.isInvalidated }.count == 0 }
            .bind { notifications, readNotifications in
                if notifications.isEmpty { return }
                let setReadNotificationIDs = Set(readNotifications.map { $0.id })
                let firstUnreadNotificationID = notifications.first { !setReadNotificationIDs.contains($0.id) }?.id ?? -1
                let sections = notifications.sorted { $0.date > $1.date }
                    .map { notice in
                        let isFirstUnread = notice.id == firstUnreadNotificationID
                        if isFirstUnread { self.updateReadNotice(for: notice.id) }
                        return NewsSection(items: [NewsFeedCellViewModel(notice: notice,
                                                                         collapsed: !isFirstUnread,
                                                                         isRead: setReadNotificationIDs.contains(notice.id),
                                                                         isUserPro: self.sessionManager.session?.isUserPro ?? false)])
                    }
                self.newsSections.accept(sections)
            }.disposed(by: disposeBag)
    }

    private func updateReadNotice(for noticeID: Int) {
        var readNotifications = localDatabase.getReadNotices() ?? [ReadNotice]()
        let setReadNotificationIDs = Set(readNotifications.map { $0.id })
        if setReadNotificationIDs.contains(noticeID) {
            return
        }
        let readNotice = ReadNotice(noticeID: noticeID)
        readNotifications.append(readNotice)
        localDatabase.saveReadNotices(readNotices: readNotifications)
    }

    func didTapNotice(at index: Int) {
        var sections = newsSections.value
        if sections.count >= index - 1, !sections[index].items.isEmpty {
            var section = sections[index]
            let notice = section.items[0]

            notice.setCollapsed(collapsed: !notice.collapsed)
            section.items[0] = notice
            sections[index] = section
            newsSections.accept(sections)
            if let noticeID = notice.id {
                updateReadNotice(for: noticeID)
            }
        }
    }
}

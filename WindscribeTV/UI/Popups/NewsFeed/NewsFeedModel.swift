//
//  NewsFeedModel.swift
//  WindscribeTV
//
//  Created by Soner Yuksel on 2025-03-14.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

import RxCocoa
import RxSwift

protocol NewsFeedModelType {
    var newsfeedData: BehaviorSubject<[NewsFeedDataModel]> { get }
    var viewToLaunch: BehaviorSubject<NewsFeedViewToLaunch> { get }
    func didTapToExpand(id: Int)
    func didTapAction(action: ActionLinkModel)
}

class NewsFeedModel: NewsFeedModelType {
    let localDatabase: LocalDatabase
    let sessionManager: SessionManaging
    let logger: FileLogger
    let htmlParser: HTMLParsing
    let disposeBag = DisposeBag()
    let newsfeedData: BehaviorSubject<[NewsFeedDataModel]> = BehaviorSubject(value: [])
    let readStatus: BehaviorSubject<[Int]> = BehaviorSubject(value: [])
    let viewToLaunch: BehaviorSubject<NewsFeedViewToLaunch> = BehaviorSubject(value: .unknown)

    init(localDatabase: LocalDatabase, sessionManager: SessionManaging, fileLogger: FileLogger, htmlParser: HTMLParsing) {
        self.localDatabase = localDatabase
        self.sessionManager = sessionManager
        self.htmlParser = htmlParser
        logger = fileLogger
        loadReadStatus()
        loadNewsFeedData()
    }

    private func loadNewsFeedData() {
        localDatabase.getNotificationsObservable()
            .take(1)
            .filter { notifications in
                notifications.map { notification in
                    notification.isInvalidated == true
                }.count > 0
            }
            .map { notifications in
                let limitedNotifications = notifications.reversed().sorted(by: { $0.id > $1.id }).prefix(5)
                let openByDefault: Int? = limitedNotifications.first(where: {
                    !self.isRead(id: $0.id)
                })?.id
                if let id = openByDefault {
                    self.updateReadNotice(for: id)
                }
                return limitedNotifications.map { notification in
                    let message = self.getMessage(description: notification.message)
                    var status = self.isRead(id: notification.id)
                    if openByDefault == notification.id {
                        status = true
                    }
                    return NewsFeedDataModel(
                        id: notification.id,
                        title: notification.title,
                        date: Date(timeIntervalSince1970: TimeInterval(notification.date)),
                        description: message.0,
                        expanded: notification.id == openByDefault ? true : false,
                        readStatus: status, actionLink: message.1)
                }
            }
            .subscribe(on: MainScheduler.asyncInstance)
            .observe(on: MainScheduler.asyncInstance)
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { newsfeedData in
                self.newsfeedData.onNext(newsfeedData)
            }, onError: { _ in }).disposed(by: disposeBag)
    }

    private func isRead(id: Int) -> Bool {
        return (try? readStatus.value().contains(id)) ?? false
    }

    private func loadReadStatus() {
        let ids = localDatabase.getReadNotices()?.compactMap { $0.id } ?? []
        readStatus.onNext(ids)
        localDatabase.getReadNoticesObservable()
            .filter { readNotificationIds in
                readNotificationIds.map { id in
                    id.isInvalidated == true
                }.count > 0
            }
            .map {
                $0.map { notice in
                    notice.id
                }
            }.compactMap { $0 }
            .subscribe(on: MainScheduler.asyncInstance)
            .observe(on: MainScheduler.asyncInstance)
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { readNotificationIds in
                self.readStatus.onNext(readNotificationIds)
            }, onError: { _ in }).disposed(by: disposeBag)
    }

    private func getMessage(description: String) -> (String, ActionLinkModel?) {
        let parsedContent = htmlParser.parse(description: description)
        return (parsedContent.message, parsedContent.actionLink)
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

    func didTapToExpand(id: Int) {
        updateReadNotice(for: id)
        let newsFeeds = (try? newsfeedData.value()) ?? []
        let updatedFeeds = newsFeeds.map { feed -> NewsFeedDataModel in
            var updatedFeed = feed
            if updatedFeed.id == id {
                updatedFeed.expanded.toggle()
                updatedFeed.animate = true
                updatedFeed.readStatus = true
            } else {
                let status = (try? self.readStatus.value().contains(feed.id)) ?? false
                updatedFeed.readStatus = status
                updatedFeed.animate = false
                updatedFeed.expanded = false
            }
            return updatedFeed
        }
        newsfeedData.onNext(updatedFeeds)
    }

    func didTapAction(action: ActionLinkModel) {
        logger.logI("Newsfeed", "User tapped on newsfeed action: \(action)")
        let queryParams = getQueryParameters(from: action.link)
        if queryParams.keys.contains("promo") {
            viewToLaunch.onNext(.payment(queryParams["promo"] ?? "", queryParams["pcpid"]))
        } else {
            if let url = URL(string: action.link) {
                viewToLaunch.onNext(.safari(url))
            } else {
                logger.logE(self, "Unable to create url from: \(action.link)")
            }
        }
    }

    private func getQueryParameters(from urlString: String) -> [String: String] {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else {
            return [:]
        }
        var parameters: [String: String] = [:]

        for item in queryItems {
            parameters[item.name] = item.value
        }
        return parameters
    }
}

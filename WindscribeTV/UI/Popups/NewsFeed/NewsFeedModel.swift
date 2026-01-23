//
//  NewsFeedModel.swift
//  WindscribeTV
//
//  Created by Soner Yuksel on 2025-03-14.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol NewsFeedModelType {
    var newsfeedData: CurrentValueSubject<[NewsFeedDataModel], Never> { get }
    var viewToLaunch: CurrentValueSubject<NewsFeedViewToLaunch, Never> { get }
    func didTapToExpand(id: Int)
    func didTapAction(action: NewsFeedActionType)
}

class NewsFeedModel: NewsFeedModelType {
    let sessionManager: SessionManager
    let notificationRepository: NotificationRepository
    let logger: FileLogger
    let htmlParser: HTMLParsing
    let newsfeedData = CurrentValueSubject<[NewsFeedDataModel], Never>([])
    let readStatus = CurrentValueSubject<[Int], Never>([])
    let viewToLaunch = CurrentValueSubject<NewsFeedViewToLaunch, Never>(.unknown)

    private var cancellables = Set<AnyCancellable>()

    init(sessionManager: SessionManager,
         fileLogger: FileLogger,
         htmlParser: HTMLParsing,
         notificationRepository: NotificationRepository) {
        self.sessionManager = sessionManager
        self.htmlParser = htmlParser
        self.notificationRepository = notificationRepository
        logger = fileLogger
        loadReadStatus()
        loadNewsFeedData()
    }

    private func loadNewsFeedData() {
        notificationRepository.notices
            .prefix(1)
            .map { notifications in
                let limitedNotifications = notifications.reversed().sorted(by: { $0.id > $1.id }).prefix(5)
                let openByDefault: Int? = limitedNotifications.first(where: {
                    !self.isRead(id: $0.id)
                })?.id
                if let id = openByDefault {
                    self.updateReadNotice(for: id)
                }

                return limitedNotifications.map { notification in
                    let (cleanMessage, parsedActionLink) = self.getMessage(description: notification.message)
                    var status = self.isRead(id: notification.id)
                    if openByDefault == notification.id {
                        status = true
                    }

                    let action: NewsFeedActionType?
                    if let parsedLink = parsedActionLink {
                        // Use standard from parsed HTML
                        action = .standard(parsedLink)
                    } else if let notificationAction = notification.action {
                        // Only fallback to promo if message had no url parse
                        action = .promo(pcpid: notificationAction.pcpid,
                                        promoCode: notificationAction.promoCode,
                                        label: notificationAction.label)
                    } else {
                        action = nil
                    }

                    return NewsFeedDataModel(
                        id: notification.id,
                        title: notification.title,
                        date: Date(timeIntervalSince1970: TimeInterval(notification.date)),
                        description: cleanMessage,
                        expanded: notification.id == openByDefault ? true : false,
                        readStatus: status,
                        action: action)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { newsfeedData in
                self.newsfeedData.send(newsfeedData)
            }
            .store(in: &cancellables)
    }

    private func isRead(id: Int) -> Bool {
        return readStatus.value.contains(id)
    }

    private func loadReadStatus() {
        readStatus.send(notificationRepository.readNotices.value)
        notificationRepository.readNotices
            .receive(on: DispatchQueue.main)
            .sink { readNotificationIds in
                self.readStatus.send(readNotificationIds)
            }
            .store(in: &cancellables)
    }

    private func getMessage(description: String) -> (String, ActionLinkModel?) {
        let parsedContent = htmlParser.parse(description: description)
        return (parsedContent.message, parsedContent.actionLink)
    }

    private func updateReadNotice(for noticeID: Int) {
        let setReadNotificationIDs = Set(notificationRepository.readNotices.value)
        if setReadNotificationIDs.contains(noticeID) {
            return
        }
        notificationRepository.readNotice(with: noticeID)
    }

    func didTapToExpand(id: Int) {
        updateReadNotice(for: id)
        let newsFeeds = newsfeedData.value
        let updatedFeeds = newsFeeds.map { feed -> NewsFeedDataModel in
            var updatedFeed = feed
            if updatedFeed.id == id {
                updatedFeed.expanded.toggle()
                updatedFeed.animate = true
                updatedFeed.readStatus = true
            } else {
                let status = self.readStatus.value.contains(feed.id)
                updatedFeed.readStatus = status
                updatedFeed.animate = false
                updatedFeed.expanded = false
            }
            return updatedFeed
        }
        newsfeedData.send(updatedFeeds)
    }

    func didTapAction(action: NewsFeedActionType) {
        logger.logI("Newsfeed", "User tapped on newsfeed action: \(action)")

        switch action {
        case .standard(let standardAction):
            if let url = URL(string: standardAction.link) {
                viewToLaunch.send(.safari(url))
            } else {
                logger.logE("NewsFeedModel", "Unable to create url from: \(standardAction.link)")
            }
        case .promo(let pcpid, let promoCode, _):
            viewToLaunch.send(.payment(promoCode ?? "", pcpid))
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

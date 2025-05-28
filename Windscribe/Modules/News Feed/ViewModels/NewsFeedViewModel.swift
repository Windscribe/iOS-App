//
//  NewsFeedViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-13.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import SwiftUI

protocol NewsFeedViewModelProtocol: ObservableObject {
    func didTapToExpand(id: Int, allowMultipleExpansions: Bool )
    func didTapAction(action: ActionLinkModel)
}

class NewsFeedViewModel: NewsFeedViewModelProtocol {

    @Published private(set) var newsFeedData: [NewsFeedDataModel] = []
    @Published var viewToLaunch: NewsFeedViewToLaunch = .unknown
    @Published var loadState: NewsFeedLoadState = .idle
    @Published private(set) var readStatus: Set<Int> = []

    private var cancellables = Set<AnyCancellable>()

    let localDatabase: LocalDatabase
    let sessionManager: SessionManaging
    let logger: FileLogger
    let router: AccountRouter
    let htmlParser: HTMLParsing

    init(localDatabase: LocalDatabase, sessionManager: SessionManaging, logger: FileLogger, router: AccountRouter, htmlParser: HTMLParsing) {
        self.localDatabase = localDatabase
        self.sessionManager = sessionManager
        self.logger = logger
        self.router = router
        self.htmlParser = htmlParser

        loadReadStatus()
        loadNewsFeedData()
    }

    // MARK: Data Loading

    func loadNewsFeedData() {
        loadState = .loading

        localDatabase.getNotificationsObservable()
            .toPublisher()
            .tryMap { notifications in
                try self.validateNotifications(notifications)
            }
            .map { self.sortAndLimitNotifications($0) }
            .map { self.mapToNewsFeedDataModels($0) }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.handleCompletion(completion)
                },
                receiveValue: { [weak self] newsfeedData in
                    self?.newsFeedData = Array(newsfeedData)
                }
            )
            .store(in: &cancellables)
    }

    // Step 1: Extract Sorting Logic
    private func sortAndLimitNotifications(_ notifications: [Notice]) -> [Notice] {
        return Array(
            notifications
                .reversed()
                .sorted { $0.date > $1.date }
                .prefix(5)
        )
    }

    // Step 2: Extract Data Mapping Logic
    private func mapToNewsFeedDataModels(_ notifications: [Notice]) -> [NewsFeedDataModel] {
        let openByDefaultID = notifications.first { !isRead(id: $0.id) }?.id

        if let id = openByDefaultID {
            self.updateReadNotice(for: id)
        }

        return notifications.enumerated().map { index, notification in
            let message = self.getMessage(description: notification.message)
            var status = self.isRead(id: notification.id)
            if openByDefaultID == notification.id {
                status = true
            }

            return NewsFeedDataModel(
                id: notification.id,
                title: notification.title,
                description: message.0,
                expanded: notification.id == openByDefaultID,
                readStatus: status,
                actionLink: message.1,
                isFirst: index == 0,
                isLast: index == notifications.count - 1
            )
        }
    }

    // Step 3: Handle Completion Separately
    private func handleCompletion(_ completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure(let error):
            self.loadState = .error("Failed to load data: \(error.localizedDescription)")
            self.logger.logE("Newsfeed", "Data Load Error: \(error)")
        case .finished:
            self.loadState = .loaded
        }
    }

    // Step 4: Extract Notification Validation
    private func validateNotifications(_ notifications: [Notice]) throws -> [Notice] {
        guard !notifications.isEmpty else {
            throw URLError(.badServerResponse)
        }
        return notifications
    }

    /// Expand/Collapse Logic
    func didTapToExpand(id: Int, allowMultipleExpansions: Bool = true) {
        newsFeedData = newsFeedData.map { item in
            var updatedItem = item

            if updatedItem.id == id {
                updatedItem.expanded.toggle()  // Expanding item animates
                updatedItem.readStatus = true
                updateReadNotice(for: id)
            } else if !allowMultipleExpansions {
                // Shrinking item — Reset rotation without animation
                if updatedItem.expanded {
                    withTransaction(Transaction(animation: .none)) {
                        updatedItem.expanded = false
                    }
                }
            }

            return updatedItem
        }
    }

    /// Read Status Persistence
    private func updateReadNotice(for noticeID: Int) {
        var readNotifications = localDatabase.getReadNotices() ?? [ReadNotice]()
        let setReadNotificationIDs = Set(readNotifications.map { $0.id })

        // Prevent duplicates
        if setReadNotificationIDs.contains(noticeID) {
            return
        }

        let readNotice = ReadNotice(noticeID: noticeID)
        readNotifications.append(readNotice)
        localDatabase.saveReadNotices(readNotices: readNotifications)
    }

    // MARK: Read Status Management

    private func isRead(id: Int) -> Bool {
        return readStatus.contains(id)
    }

    private func loadReadStatus() {
        loadState = .loading

        localDatabase.getReadNoticesObservable()
            .toPublisher()
            .tryMap { readNotices -> [Int] in
                guard !readNotices.isEmpty else {
                    throw NSError(
                        domain: "EmptyData",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "No read notices found."])
                }
                return readNotices.compactMap { $0.id }
            }
            .catch { [weak self] error -> Just<[Int]> in
                self?.logger.logE("ReadStatus", "Failed to load read notices: \(error.localizedDescription)")
                return Just([])
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] readNotificationIds in
                self?.readStatus = Set(readNotificationIds)
                self?.loadState = .loaded
            }
            .store(in: &cancellables)
    }

    // MARK: Action Handling

    func didTapAction(action: ActionLinkModel) {
        logger.logI("Newsfeed", "User tapped on newsfeed action: \(action)")
        let queryParams = getQueryParameters(from: action.link)

        if queryParams.keys.contains("promo") {
            handlePayment(promoCode: queryParams["promo"] ?? "", pcpid: queryParams["pcpid"])
        } else if isValidURL(action.link), let url = URL(string: action.link) {
            viewToLaunch = .safari(url)
        } else {
            logger.logE("Newsfeed", "Invalid URL: \(action.link)")
        }
    }

    /// Payment Flow Extraction
    private func handlePayment(promoCode: String, pcpid: String?) {
        viewToLaunch = .payment(promoCode, pcpid)
    }

    /// Improved URL Validation
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: HTML Parsing

    private func getMessage(description: String) -> (String, ActionLinkModel?) {
        let parsedContent = htmlParser.parse(description: description)
        return (parsedContent.message, parsedContent.actionLink)
    }

    /// Extract Query Parameters
    private func getQueryParameters(from urlString: String) -> [String: String] {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else { return [:] }

        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value
        }
        return parameters
    }
}

// MARK: Navigation type action

extension NewsFeedViewModel {

    func navigateToPromotionView(
        with promoCode: String,
        and pcpID: String?,
        from presentingController: UIViewController?) {
        if let presentingController = presentingController {
            router.routeTo(to: .upgrade(promoCode: promoCode, pcpID: pcpID), from: presentingController)
        }
    }
}

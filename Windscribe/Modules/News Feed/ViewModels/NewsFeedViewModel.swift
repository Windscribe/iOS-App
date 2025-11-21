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
    func didTapAction(action: NewsFeedActionType)

    var isDarkMode: Bool { get set }
}

class NewsFeedViewModel: NewsFeedViewModelProtocol {

    @Published private(set) var newsFeedData: [NewsFeedDataModel] = []
    @Published var viewToLaunch: NewsFeedViewToLaunch = .unknown
    @Published var loadState: NewsFeedLoadState = .idle
    @Published private(set) var readStatus: Set<Int> = []
    @Published var isDarkMode: Bool = false

    let localDatabase: LocalDatabase
    let sessionManager: SessionManager
    let lookAndFeelRepository: LookAndFeelRepositoryType
    let logger: FileLogger
    let router: AccountRouter
    let htmlParser: HTMLParsing
    let notificationRepository: NotificationRepository

    private var cancellables = Set<AnyCancellable>()

    init(localDatabase: LocalDatabase,
         sessionManager: SessionManager,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         logger: FileLogger,
         router: AccountRouter,
         htmlParser: HTMLParsing,
         notificationRepository: NotificationRepository) {
        self.localDatabase = localDatabase
        self.sessionManager = sessionManager
        self.lookAndFeelRepository = lookAndFeelRepository
        self.logger = logger
        self.router = router
        self.htmlParser = htmlParser
        self.notificationRepository = notificationRepository

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
            }
            .store(in: &cancellables)
    }

    // MARK: Data Loading

    @MainActor
    func loadNewsFeedData() async {
        loadState = .loading

        // Load read status FIRST (synchronously) to ensure it's available during mapping
        loadReadStatus()

        do {
            let notifications = try await notificationRepository.getUpdatedNotifications()
            let validated = try validateNotifications(notifications)
            let sorted = sortNotifications(validated)
            let mapped = mapToNewsFeedDataModels(sorted)

            self.newsFeedData = Array(mapped)
            self.loadState = .loaded
        } catch {
            self.loadState = .error("\(TextsAsset.failedToLoadData): \(error.localizedDescription)")
            self.logger.logE("Newsfeed", "Data Load Error: \(error)")
        }
    }

    // Step 1: Extract Sorting Logic - Take 5 newest by date
    private func sortNotifications(_ notifications: [Notice]) -> [Notice] {
        return Array(
            notifications
                .reversed()
                .sorted { $0.date > $1.date }
                .prefix(5)  // Show only 5 newest notifications
        )
    }

    // Step 2: Extract Data Mapping Logic
    private func mapToNewsFeedDataModels(_ notifications: [Notice]) -> [NewsFeedDataModel] {
        let openByDefaultID = notifications.first { !isRead(id: $0.id) }?.id

        if let id = openByDefaultID {
            self.updateReadNotice(for: id)
        }

        return notifications.enumerated().map { index, notification in
            let (cleanMessage, parsedActionLink) = self.getMessage(description: notification.message)
            var status = self.isRead(id: notification.id)
            if openByDefaultID == notification.id {
                status = true
            }

            let action: NewsFeedActionType?
            if let notificationAction = notification.action {
                // Prioritize API action (promo) over HTML link
                action = .promo(pcpid: notificationAction.pcpid,
                                promoCode: notificationAction.promoCode,
                                label: notificationAction.label)
            } else if let parsedLink = parsedActionLink {
                // Fallback to HTML link if no API action
                action = .standard(parsedLink)
            } else {
                action = nil
            }

            return NewsFeedDataModel(
                id: notification.id,
                title: notification.title,
                date: Date(timeIntervalSince1970: TimeInterval(notification.date)),
                description: cleanMessage,
                expanded: notification.id == openByDefaultID,
                readStatus: status,
                action: action,
                isFirst: index == 0,
                isLast: index == notifications.count - 1
            )
        }
    }

    // Step 3: Extract Notification Validation
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
        // Prevent duplicates
        if readStatus.contains(noticeID) {
            return
        }

        // Update in-memory cache immediately
        readStatus.insert(noticeID)

        // Persist to database
        var readNotifications = localDatabase.getReadNotices() ?? [ReadNotice]()
        let readNotice = ReadNotice(noticeID: noticeID)
        readNotifications.append(readNotice)
        localDatabase.saveReadNotices(readNotices: readNotifications)
    }

    // MARK: Read Status Management

    private func isRead(id: Int) -> Bool {
        return readStatus.contains(id)
    }

    private func loadReadStatus() {
        // Get initial value synchronously
        let initialReadNotices = localDatabase.getReadNotices() ?? []
        let readNotificationIds = initialReadNotices.compactMap { $0.id }
        self.readStatus = Set(readNotificationIds)

        // Keep reactive subscription for future updates
        localDatabase.getReadNoticesObservable()
            .toPublisher()
            .catch { [weak self] error -> Just<[ReadNotice]> in
                self?.logger.logE("ReadStatus", "Failed to observe read notices: \(error.localizedDescription)")
                return Just([])
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] readNotices in
                let readNotificationIds = readNotices.compactMap { $0.id }
                let newReadStatus = Set(readNotificationIds)
                // Merge with existing instead of replacing to avoid race conditions
                self?.readStatus.formUnion(newReadStatus)
            }
            .store(in: &cancellables)
    }

    // MARK: Action Handling

    func didTapAction(action: NewsFeedActionType) {
        logger.logI("Newsfeed", "User tapped on newsfeed action: \(action.actionText)")

        switch action {
        case .standard(let standardAction):
            if isValidURL(standardAction.link), let url = URL(string: standardAction.link) {
                viewToLaunch = .safari(url)
            } else {
                logger.logE("Newsfeed", "Invalid standard action URL: \(standardAction.link)")
            }

        case .promo(let pcpid, let promoCode, _):
            let code = promoCode ?? ""
            handlePayment(promoCode: code, pcpid: pcpid)
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

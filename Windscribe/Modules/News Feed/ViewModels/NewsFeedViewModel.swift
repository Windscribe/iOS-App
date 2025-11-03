//
//  NewsFeedViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-13.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import SwiftUI
import RxSwift

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

    func loadNewsFeedData() {
        loadState = .loading

        notificationRepository.getUpdatedNotifications()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .tryMap { notifications in
                try self.validateNotifications(notifications)
            }
            .map { self.sortNotifications($0) }
            .map { self.mapToNewsFeedDataModels($0) }
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.handleCompletion(completion)
                },
                receiveValue: { [weak self] newsfeedData in
                    self?.newsFeedData = Array(newsfeedData)
                }
            )
            .store(in: &cancellables)

        loadReadStatus()
    }

    // Step 1: Extract Sorting Logic
    private func sortNotifications(_ notifications: [Notice]) -> [Notice] {
        return Array(
            notifications
                .reversed()
                .sorted { $0.date > $1.date }
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
                expanded: notification.id == openByDefaultID,
                readStatus: status,
                action: action,
                isFirst: index == 0,
                isLast: index == notifications.count - 1
            )
        }
    }

    // Step 3: Handle Completion Separately
    private func handleCompletion(_ completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure(let error):
            self.loadState = .error("\(TextsAsset.failedToLoadData): \(error.localizedDescription)")
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

//
//  RestrictiveNetworkViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-14.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol RestrictiveNetworkViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var shouldDismiss: Bool { get set }
    var isExportingLogs: Bool { get set }
    var safariURL: URL? { get }
    var showShareSheet: Bool { get set }
    var logContentToShare: String { get set }

    func exportLogs()
    func contactSupport()
    func cancel()
}

final class RestrictiveNetworkViewModelImpl: RestrictiveNetworkViewModel {
    @Published var isDarkMode: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var isExportingLogs: Bool = false
    @Published var safariURL: URL?
    @Published var showShareSheet: Bool = false
    @Published var logContentToShare: String = ""

    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let pushNotificationsManager: PushNotificationManagerV2
    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         pushNotificationsManager: PushNotificationManagerV2) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.pushNotificationsManager = pushNotificationsManager

        bind()
    }

    private func bind() {
        // Theme subscription using RxSwift bridge
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("RestrictiveNetworkViewModel", "Theme subscription error: \(error)")
                }
            }, receiveValue: { [weak self] in
                self?.isDarkMode = $0
            })
            .store(in: &cancellables)
    }

    func exportLogs() {
        logger.logI("RestrictiveNetworkViewModel", "Starting log export...")
        isExportingLogs = true

        Task {
            do {
                let logContent = try await logger.getLogData()
                await MainActor.run {
                    self.isExportingLogs = false
                    self.logContentToShare = logContent
                    self.showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    self.isExportingLogs = false
                    self.logger.logE("RestrictiveNetworkViewModel", "Failed to export logs: \(error)")
                }
            }
        }
    }

    func contactSupport() {
        logger.logI("RestrictiveNetworkViewModel", "Opening contact support page.")
        safariURL = URL(string: Links.contactSupport)
    }

    func cancel() {
        shouldDismiss = true
    }
}

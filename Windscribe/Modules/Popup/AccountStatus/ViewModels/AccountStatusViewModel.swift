//
//  AccountStatusViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-29.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol AccountStatusViewModel: ObservableObject {
    var isDarkMode: Bool { get }
    var accountStatusType: AccountStatusType { get }
    var shouldDismiss: Bool { get }
    var showUpgrade: Bool { get }

    func updateAccountStatusType(_ type: AccountStatusType)
    func primaryAction()
    func secondaryAction()
}

final class AccountStatusViewModelImpl: AccountStatusViewModel {
    @Published var isDarkMode: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var showUpgrade: Bool = false

    @Published var accountStatusType: AccountStatusType

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let logger: FileLogger
    private let userSessionRepository: UserSessionRepository

    private var cancellables = Set<AnyCancellable>()

    init(accountStatusType: AccountStatusType = .banned,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         logger: FileLogger,
         userSessionRepository: UserSessionRepository) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.logger = logger
        self.userSessionRepository = userSessionRepository

        self.accountStatusType = accountStatusType

        bind()
    }

    func updateAccountStatusType(_ type: AccountStatusType) {
        self.accountStatusType = type
    }

    var displayDescription: String {
        return accountStatusType.description
    }

    var resetDate: String {
        switch accountStatusType {
        case .outOfData:
            return userSessionRepository.sessionModel?.getNextReset() ?? ""
        default:
            return ""
        }
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
            }
            .store(in: &cancellables)
    }

    func primaryAction() {
        guard accountStatusType.canTakeAction else {
            logger.logD("AccountStatusViewModel", "Primary action blocked for banned account")
            return
        }

        switch accountStatusType {
        case .banned:
            // No action for banned accounts
            shouldDismiss = true
        case .outOfData, .proPlanExpired:
            showUpgrade = true
            // Don't dismiss immediately - let the upgrade sheet handle dismissal
        }
    }

    func secondaryAction() {
        shouldDismiss = true
    }
}

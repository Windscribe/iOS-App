//
//  ConfirmEmailViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-28.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UIKit

protocol ConfirmEmailViewModel {
    var isDarkMode: Bool { get set }

    func getSession()
    func updateSession()
}

final class ConfirmEmailViewModelImpl: ObservableObject, ConfirmEmailViewModel {

    @Published var session: SessionModel?
    @Published var resendButtonDisabled: Bool = false
    @Published var resendEmailSuccess: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var isDarkMode: Bool = false

    private let userSessionRepository: UserSessionRepository
    private let sessionManager: SessionManager
    private let localDatabase: LocalDatabase
    private let apiManager: APIManager
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType

    private var cancellables = Set<AnyCancellable>()

    init(userSessionRepository: UserSessionRepository,
         sessionManager: SessionManager,
         localDatabase: LocalDatabase,
         apiManager: APIManager,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         logger: FileLogger) {
        self.userSessionRepository = userSessionRepository
        self.sessionManager = sessionManager
        self.localDatabase = localDatabase
        self.apiManager = apiManager
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository

        bind()
        observeSession()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
            }
            .store(in: &cancellables)
    }

    private func observeSession() {
        getSession()

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateSession()
            }
            .store(in: &cancellables)
    }

    func getSession() {
        userSessionRepository.sessionModelSubject
            .sink { [weak self] session in
                self?.session = session
                if session?.emailStatus == true {
                    self?.shouldDismiss = true
                }
            }
            .store(in: &cancellables)
    }

    func updateSession() {
        sessionManager.keepSessionUpdated()
    }

    func resendEmail() {
        resendButtonDisabled = true

        Task { [weak self] in
            guard let self = self else { return }

            do {
                _ = try await self.apiManager.confirmEmail()
                await MainActor.run {
                    self.resendEmailSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.resendButtonDisabled = false
                }
            }
        }
    }
}

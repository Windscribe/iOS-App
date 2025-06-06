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

    @Published var session: Session?
    @Published var resendButtonDisabled: Bool = false
    @Published var resendEmailSuccess: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var isDarkMode: Bool = false

    private let sessionManager: SessionManaging
    private let localDatabase: LocalDatabase
    private let apiManager: APIManager
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType

    private var cancellables = Set<AnyCancellable>()

    init(sessionManager: SessionManaging,
         localDatabase: LocalDatabase,
         apiManager: APIManager,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         logger: FileLogger) {
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
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ConfirmEmailViewModel", "darkTheme error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
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
        localDatabase.getSession()
            .toPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] session in
                self?.session = session
                if session?.emailStatus == true {
                    self?.shouldDismiss = true
                }
            })
            .store(in: &cancellables)
    }

    func updateSession() {
        sessionManager.keepSessionUpdated()
    }

    func resendEmail() {
        resendButtonDisabled = true

        apiManager.confirmEmail()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.resendButtonDisabled = false
                }
            }, receiveValue: { [weak self] _ in
                self?.resendEmailSuccess = true
            })
            .store(in: &cancellables)
    }
}

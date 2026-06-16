//
//  SendTicketViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol SendTicketViewModel: ObservableObject {
    // Input Fields
    var email: String { get set }
    var subject: String { get set }
    var message: String { get set }
    var category: String { get set }

    // UI State
    var isDarkMode: Bool { get }
    var showProgress: Bool { get }
    var showSuccess: Bool { get }
    var showError: Bool { get }
    var errorMessage: String { get }
    var safariURL: URL? { get set }

    // Derived State
    var isFormValid: Bool { get }

    // Actions
    func sendTicket()
}

final class SendTicketViewModelImpl: SendTicketViewModel {

    // Input
    @Published var email: String = ""
    @Published var subject: String = ""
    @Published var message: String = ""
    @Published var category: String = TextsAsset.SubmitTicket.categories.first ?? ""

    // UI State
    @Published var isDarkMode: Bool = false
    @Published var showProgress: Bool = false
    @Published var showSuccess: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var safariURL: URL?

    // Dependencies
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let userSessionRepository: UserSessionRepository

    // Cancellables
    private var cancellables = Set<AnyCancellable>()

    // Derived
    var isFormValid: Bool {
        email.isValidEmail() && !subject.isEmpty && !message.isEmpty
    }

    init(
        lookAndFeelRepository: LookAndFeelRepositoryType,
        userSessionRepository: UserSessionRepository
    ) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.userSessionRepository = userSessionRepository

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
            }
            .store(in: &cancellables)

        if let userEmail = userSessionRepository.sessionModel?.email {
            self.email = userEmail
        }
    }

    func sendTicket() {
        let supportText = [subject, message]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        guard let url = LinkProvider.getKnowledgeBaseGarryURL(message: supportText) else {
            errorMessage = TextsAsset.SubmitTicket.failedToSendTicket
            showError = true
            return
        }

        showError = false
        safariURL = url
    }
}

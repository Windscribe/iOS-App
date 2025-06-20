//
//  SendTicketViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UIKit

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

    // Dependencies
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let sessionManager: SessionManaging
    private let apiManager: APIManager

    // Cancellables
    private var cancellables = Set<AnyCancellable>()

    // Derived
    var isFormValid: Bool {
        email.isValidEmail() && !subject.isEmpty && !message.isEmpty
    }

    init(
        apiManager: APIManager,
        lookAndFeelRepository: LookAndFeelRepositoryType,
        sessionManager: SessionManaging
    ) {
        self.apiManager = apiManager
        self.lookAndFeelRepository = lookAndFeelRepository
        self.sessionManager = sessionManager

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
            .store(in: &cancellables)

        if let userEmail = sessionManager.session?.email {
            self.email = userEmail
        }
    }

    func sendTicket() {
        guard let categoryIndex = TextsAsset.SubmitTicket.categories.firstIndex(of: category) else { return }

        showProgress = true
        showSuccess = false
        showError = false

        let device = UIDevice.current
        let platform = "Brand: Apple | OS: \(device.systemVersion) | Model: \(UIDevice.modelName)"
        let name = sessionManager.session?.userId ?? ""

        apiManager.sendTicket(
            email: email,
            name: name,
            subject: subject,
            message: message,
            category: "\(categoryIndex + 1)",
            type: category, channel: "app_ios", platform: platform)
                .asPublisher()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.showProgress = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription.isEmpty
                            ? TextsAsset.SubmitTicket.failedToSendTicket
                            : error.localizedDescription
                        self?.showError = true
                    }
                }, receiveValue: { [weak self] _ in
                    self?.showSuccess = true
                })
                .store(in: &cancellables)
    }
}

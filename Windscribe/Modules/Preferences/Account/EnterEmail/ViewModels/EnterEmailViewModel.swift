//
//  EnterEmailViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-10.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol EnterEmailViewModel: ObservableObject {
    var email: String { get set }
    var emailIsValid: Bool { get }
    var isDarkMode: Bool { get set }
    var showLoading: Bool { get }
    var showGet10GBPromo: Bool { get }
    var emailInfoText: String { get }
    var infoLabelText: String { get }
    var titleText: String { get }

    var submitEmailResult: PassthroughSubject<Result<Void, EmailError>, Never> { get }

    func submit()
}

final class EnterEmailViewModelImpl: EnterEmailViewModel {

    @Published var email: String = ""
    @Published var isDarkMode: Bool = false
    @Published private(set) var showLoading: Bool = false

    private let sessionManager: SessionManager
    private let alertManager: AlertManagerV2
    private let apiManager: APIManager

    private let lookAndFeelRepository: LookAndFeelRepositoryType

    private var cancellables = Set<AnyCancellable>()

    let submitEmailResult = PassthroughSubject<Result<Void, EmailError>, Never>()

    let emailInfoText = TextsAsset.get10GbAMonth
    let infoLabelText = TextsAsset.addEmailInfo
    let titleText = TextsAsset.addEmail

    var emailIsValid: Bool {
        email.count > 3 && email.contains("@") && email.contains(".")
    }

    var showGet10GBPromo: Bool {
        !(sessionManager.session?.isUserPro ?? false)
    }

    init(sessionManager: SessionManager,
         alertManager: AlertManagerV2,
         apiManager: APIManager,
         lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.sessionManager = sessionManager
        self.alertManager = alertManager
        self.apiManager = apiManager
        self.lookAndFeelRepository = lookAndFeelRepository

        self.email = sessionManager.session?.email ?? ""

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

    func submit() {
        guard emailIsValid else { return }

        showLoading = true

        Task { [weak self] in
            guard let self = self else { return }
            do {
                _ = try await apiManager.addEmail(email: email)
                await MainActor.run {
                    self.sessionManager.keepSessionUpdated()
                    self.submitEmailResult.send(.success(()))
                    self.showLoading = false
                }
            } catch {
                await MainActor.run {
                    self.submitEmailResult.send(.failure(EmailError.from(error)))
                    self.showLoading = false
                }
            }
        }
    }
}

enum EmailError: LocalizedError {
    case emailExists
    case disposable
    case cannotChange
    case noNetwork
    case generic

    var errorDescription: String? {
        switch self {
        case .emailExists:
            return TextsAsset.emailIsTaken
        case .disposable:
            return TextsAsset.disposableEmail
        case .cannotChange:
            return TextsAsset.cannotChangeExistingEmail
        case .noNetwork:
            return TextsAsset.noNetworksAvailable
        case .generic:
            return TextsAsset.pleaseContactSupport
        }
    }

    static func from(_ error: Error) -> EmailError {
        if case let Errors.apiError(apiError) = error {
            if let message = apiError.errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines) {
                switch message {
                case TextsAsset.emailIsTaken:
                    return .emailExists
                case TextsAsset.disposableEmail:
                    return .disposable
                case TextsAsset.cannotChangeExistingEmail:
                    return .cannotChange
                case TextsAsset.noNetworksAvailable:
                    return .noNetwork
                default:
                    return .generic
                }
            }
        }

        return .generic
    }
}

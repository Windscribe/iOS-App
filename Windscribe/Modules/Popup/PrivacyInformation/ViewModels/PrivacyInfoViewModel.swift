//
//  PrivacyInfoViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol PrivacyInfoViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var shouldDismiss: Bool { get set }

    func acceptPrivacy()
}

final class PrivacyInfoViewModelImpl: PrivacyInfoViewModel {
    @Published var isDarkMode: Bool = false
    @Published var shouldDismiss: Bool = false

    private let preferences: Preferences
    private let networkRepository: SecuredNetworkRepository
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let privacyStateManager: PrivacyStateManaging
    private var cancellables = Set<AnyCancellable>()

    init(preferences: Preferences,
         networkRepository: SecuredNetworkRepository,
         localDatabase: LocalDatabase,
         logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         privacyStateManager: PrivacyStateManaging) {
        self.preferences = preferences
        self.networkRepository = networkRepository
        self.localDatabase = localDatabase
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.privacyStateManager = privacyStateManager

        bind()
    }

    private func bind() {
        // Theme subscription using RxSwift bridge
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("PrivacyInfoViewModel", "Theme subscription error: \(error)")
                }
            }, receiveValue: { [weak self] in
                self?.isDarkMode = $0
            })
            .store(in: &cancellables)
    }


    func acceptPrivacy() {
        logger.logD("PrivacyInfoViewModel", "User accepted privacy conditions.")

        // Save privacy acceptance
        preferences.savePrivacyPopupAccepted(bool: true)

        // Post reachability notification (legacy requirement)
        NotificationCenter.default.post(Notification(name: Notifications.reachabilityChanged))

        // Set default protocol configuration
        setupDefaultProtocol()

        // Notify state manager (this is what MainViewController observes)
        privacyStateManager.notifyPrivacyAccepted()

        // Dismiss the view
        shouldDismiss = true
    }

    private func setupDefaultProtocol() {
        var defaultProtocol = TextsAsset.General.protocols[0]
        var defaultPort = localDatabase.getPorts(protocolType: defaultProtocol)?.first ?? "443"

        if let suggestedProtocol = localDatabase.getSuggestedPorts()?.first,
           suggestedProtocol.protocolType != "",
           suggestedProtocol.port != "" {
            defaultProtocol = suggestedProtocol.protocolType
            defaultPort = suggestedProtocol.port
            logger.logD("PrivacyInfoViewModel", "Detected Suggested Protocol: Protocol selection set to \(suggestedProtocol.protocolType):\(suggestedProtocol.port)")
        } else {
            logger.logD("PrivacyInfoViewModel", "Used Default Protocol: Protocol selection set to \(defaultProtocol):\(defaultPort)")
        }

        localDatabase.updateConnectionMode(value: Fields.Values.manual)
        networkRepository.updateNetworkPreferredProtocol(with: defaultProtocol, andPort: defaultPort)
    }
}

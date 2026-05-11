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
    private let networkRepository: WifiNetworkRepository
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let privacyStateManager: PrivacyStateManaging
    private let portMapRepository: PortMapRepository
    private var cancellables = Set<AnyCancellable>()

    init(preferences: Preferences,
         networkRepository: WifiNetworkRepository,
         logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         privacyStateManager: PrivacyStateManaging,
         portMapRepository: PortMapRepository) {
        self.preferences = preferences
        self.networkRepository = networkRepository
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.privacyStateManager = privacyStateManager
        self.portMapRepository = portMapRepository

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isDarkMode = $0
            }
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
        var defaultProtocol = VPNProtocolType.wireGuard.identifier
        var defaultPort = portMapRepository.getPorts(protocolType: defaultProtocol)?.first ?? "443"

        if let suggestedPorts = portMapRepository.suggestedPorts,
           suggestedPorts.protocolType != "",
           suggestedPorts.port != "" {
            defaultProtocol = suggestedPorts.protocolType
            defaultPort = suggestedPorts.port
            logger.logD("PrivacyInfoViewModel", "Detected Suggested Protocol: Protocol selection set to \(suggestedPorts.protocolType):\(suggestedPorts.port)")
        } else {
            logger.logD("PrivacyInfoViewModel", "Used Default Protocol: Protocol selection set to \(defaultProtocol):\(defaultPort)")
        }

        preferences.saveConnectionMode(mode: Fields.Values.auto)
        networkRepository.updateNetworkPreferredProtocol(with: defaultProtocol, andPort: defaultPort)
    }
}

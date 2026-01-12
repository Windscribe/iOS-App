//
//  PrivacyViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol PrivacyViewModelType {
    func action()
    func action(completionHandler: @escaping (() -> Void))
}

class PrivacyViewModel: PrivacyViewModelType {
    // MARK: - Dependencies

    let preferences: Preferences
    let networkRepository: WifiNetworkRepository
    let localDatabase: LocalDatabase
    let logger: FileLogger
    private let portMapRepository: PortMapRepository

    init(preferences: Preferences,
         networkRepository: WifiNetworkRepository,
         localDatabase: LocalDatabase,
         logger: FileLogger,
         portMapRepository: PortMapRepository,) {
        self.preferences = preferences
        self.networkRepository = networkRepository
        self.localDatabase = localDatabase
        self.logger = logger
        self.portMapRepository = portMapRepository
    }

    func action(completionHandler: @escaping (() -> Void)) {
        actionWithCompletion(completionHandler: completionHandler)
    }

    func action() {
        actionWithCompletion()
    }

    private func actionWithCompletion(completionHandler: (() -> Void)? = nil) {
        preferences.savePrivacyPopupAccepted(bool: true)
        NotificationCenter.default.post(Notification(name: Notifications.reachabilityChanged))
        var defaultProtocol = TextsAsset.General.protocols[0]
        var defaultPort = localDatabase.getPorts(protocolType: defaultProtocol)?.first ?? "443"

        if let suggestedPorts = portMapRepository.suggestedPorts,
           suggestedPorts.protocolType != "",
           suggestedPorts.port != "" {
            defaultProtocol = suggestedPorts.protocolType
            defaultPort = suggestedPorts.port
            logger.logD("PrivacyViewModel", "Detected Suggested Protocol: Protocol selection set to \(suggestedPorts.protocolType):\(suggestedPorts.port)")
        } else {
            logger.logD("PrivacyViewModel", "Used Default Protocol: Protocol selection set to \(defaultProtocol):\(defaultPort)")
        }

        preferences.saveConnectionMode(mode: Fields.Values.manual)
        networkRepository.updateNetworkPreferredProtocol(with: defaultProtocol, andPort: defaultPort)
        completionHandler?()
    }
}

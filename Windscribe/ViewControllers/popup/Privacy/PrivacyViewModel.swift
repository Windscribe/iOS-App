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
    let networkRepository: SecuredNetworkRepository
    let localDatabase: LocalDatabase
    let logger: FileLogger

    init(preferences: Preferences,
         networkRepository: SecuredNetworkRepository,
         localDatabase: LocalDatabase,
         logger: FileLogger) {
        self.preferences = preferences
        self.networkRepository = networkRepository
        self.localDatabase = localDatabase
        self.logger = logger
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
        var defaultPort = self.localDatabase.getPorts(protocolType: defaultProtocol)?.first ?? "443"
        if let suggestedProtocol = self.localDatabase.getSuggestedPorts()?.first,
           suggestedProtocol.protocolType != "",
           suggestedProtocol.port != "" {
            defaultProtocol = suggestedProtocol.protocolType
            defaultPort = suggestedProtocol.port
            self.logger.logD(self, "Detected Suggested Protocol: Protocol selection set to \(suggestedProtocol.protocolType):\(suggestedProtocol.port)")
        } else {
            self.logger.logD(self, "Used Default Protocol: Protocol selection set to \(defaultProtocol):\(defaultPort)")
        }
        self.localDatabase.updateConnectionMode(value: Fields.Values.manual)
        self.networkRepository.updateNetworkPreferredProtocol(with: defaultProtocol, andPort: defaultPort)
        completionHandler?()
    }
}

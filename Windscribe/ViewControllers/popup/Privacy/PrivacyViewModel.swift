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
}

class PrivacyViewModel: PrivacyViewModelType {
    // MARK: - Dependencies
    let preferences: Preferences
    let networkRepository: SecuredNetworkRepository
    let localDatabase: LocalDatabase
    let sharedVPNManager: IKEv2VPNManager
    let logger: FileLogger

    init(preferences: Preferences,
         networkRepository: SecuredNetworkRepository,
         localDatabase: LocalDatabase,
         sharedVPNManager: IKEv2VPNManager,
         logger: FileLogger) {
        self.preferences = preferences
        self.networkRepository = networkRepository
        self.localDatabase = localDatabase
        self.sharedVPNManager = sharedVPNManager
        self.logger = logger
    }

    func action() {
        preferences.savePrivacyPopupAccepted(bool: true)
        sharedVPNManager.configureDummy {[weak self] _,_ in
            guard let self = self else { return }
            NotificationCenter.default.post(Notification(name: Notifications.reachabilityChanged))
            guard let suggestedProtocol = self.localDatabase.getSuggestedPorts()?.first,
                  suggestedProtocol.protocolType != "",
                  suggestedProtocol.port != "" else { return }
            self.localDatabase.updateConnectionMode(value: Fields.Values.manual)

            if let wifiNetwork = self.networkRepository.getCurrentNetwork() {
                wifiNetwork.protocolType = suggestedProtocol.protocolType
                wifiNetwork.port = suggestedProtocol.port
                self.networkRepository.setNetworkPreferredProtocol(network: wifiNetwork)

                self.logger.logD(self, "Detected Suggested Protocol: Protocol selection set to \(suggestedProtocol.protocolType):\(suggestedProtocol.port)")
            }
        }
    }
}

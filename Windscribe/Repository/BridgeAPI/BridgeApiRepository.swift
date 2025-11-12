//
//  BridgeApiRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol BridgeApiRepository {
    var bridgeIsAvailable: CurrentValueSubject<Bool, Never> { get }
    var isReady: Bool { get }
}

class BridgeApiRepositoryImpl: BridgeApiRepository {
    private let bridgeAPI: WSNetBridgeAPI
    private let locationManager: LocationsManager
    private let userSessionRepository: UserSessionRepository
    private let preferences: Preferences

    let bridgeIsAvailable =  CurrentValueSubject<Bool, Never>(false)
    var isReady: Bool {
        bridgeIsAvailable.value
    }

    init(bridgeAPI: WSNetBridgeAPI,
         locationManager: LocationsManager,
         userSessionRepository: UserSessionRepository,
         preferences: Preferences) {
        self.bridgeAPI = bridgeAPI
        self.locationManager = locationManager
        self.userSessionRepository = userSessionRepository
        self.preferences = preferences
        observeBridgeApi()
    }

    private func observeBridgeApi() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.bridgeAPI.setApiAvailableCallback { [weak self] ready in
                guard let self = self else { return }
                if ready {
                    preferences.saveServerSettings(settings: WSNet.instance().currentPersistentSettings())
                }
                guard let user = self.userSessionRepository.user else {
                    self.bridgeIsAvailable.send(false)
                    return
                }
                let locationInfo = self.locationManager.getLocationUIInfo()
                guard locationInfo.isServer else {
                    self.bridgeIsAvailable.send(false)
                    return
                }

                let hasAlc = user.alcList.first { $0 == locationInfo.countryCode } != nil
                self.bridgeIsAvailable.send(ready && (user.isPro || hasAlc))
            }
        }
    }
}

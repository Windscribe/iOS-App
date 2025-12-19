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
    private var cancellables = Set<AnyCancellable>()
    private var startTimeStamp = Date()
    private var initialListenning = true

    private let bridgeAPI: WSNetBridgeAPI
    private let locationManager: LocationsManager
    private let userSessionRepository: UserSessionRepository
    private let vpnStateRepository: VPNStateRepository
    private let logger: FileLogger
    private let protocolManager: ProtocolManagerType
    private let preferences: Preferences

    let bridgeIsAvailable =  CurrentValueSubject<Bool, Never>(false)
    var isReady: Bool {
        bridgeIsAvailable.value
    }

    init(bridgeAPI: WSNetBridgeAPI,
         locationManager: LocationsManager,
         userSessionRepository: UserSessionRepository,
         vpnStateRepository: VPNStateRepository,
         logger: FileLogger,
         protocolManager: ProtocolManagerType,
         preferences: Preferences) {
        self.bridgeAPI = bridgeAPI
        self.locationManager = locationManager
        self.userSessionRepository = userSessionRepository
        self.vpnStateRepository = vpnStateRepository
        self.logger = logger
        self.protocolManager = protocolManager
        self.preferences = preferences
        observeBridgeApi()
    }

    private func observeBridgeApi() {
        vpnStateRepository.getStatus()
            .map { $0 == .connected }
            .removeDuplicates()
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                if !isConnected {
                    self.logger.logI("BridgeApiRepository", "wsnet BridgeAPI_impl VPN Disconnected setting bridgeAPI to Connected State: false")
                    self.bridgeAPI.setConnectedState(false)
                    self.logger.logI("BridgeApiRepository", "wsnet setIsConnectedToVpnState to false")
                    WSNet.instance().setIsConnectedToVpnState(false)
                }
                guard initialListenning else { return }
                guard Date().timeIntervalSince(startTimeStamp) < 1 else {
                    initialListenning = false
                    return
                }
                if isConnected {
                    initialListenning = false
                    let currentHost = preferences.getLastNodeIP() ?? ""
                    let currentProtocol = vpnStateRepository.vpnInfo.value?.selectedProtocol ?? ""
                    if currentProtocol == "WireGuard" {
                        self.bridgeAPI.setCurrentHost(currentHost)
                    } else {
                        self.bridgeAPI.setCurrentHost("")
                    }
                    self.bridgeAPI.setIgnoreSslErrors(true)
                    self.bridgeAPI.setConnectedState(true)
                    Task {
                        // we need to wait on the first time, other wise we might might the tokens for bridge api
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        WSNet.instance().setIsConnectedToVpnState(isConnected)
                    }
                }
            }
            .store(in: &cancellables)

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.bridgeAPI.setApiAvailableCallback { [weak self] ready in
                self?.checkAndEmitApiAvailability(ready: ready)
            }
        }
    }

    private func checkAndEmitApiAvailability(ready: Bool) {
        if ready {
            preferences.saveServerSettings(settings: WSNet.instance().currentPersistentSettings())
            let persistantSettings = WSNet.instance().currentPersistentSettings()
        }
        guard let sessionModel = self.userSessionRepository.sessionModel else {
            self.bridgeIsAvailable.send(false)
            logger.logI("BridgeApiRepository", "userSessionRepository.sessionModel - nil")
            return
        }
        let locationInfo = self.locationManager.getLocationUIInfo()
        guard locationInfo.isServer else {
            self.bridgeIsAvailable.send(false)
            logger.logI("BridgeApiRepository", "locationInfo - nil")
            return
        }

        let hasAlc = sessionModel.alc.contains(locationInfo.countryCode)
        self.bridgeIsAvailable.send(ready && (sessionModel.isUserPro || hasAlc))
    }
}

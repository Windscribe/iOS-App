//
//  EmergencyConnectViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-02.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

enum EmergencyConnectState {
    case disconnected
    case disconnecting
    case connecting
    case connected
}

protocol EmergencyConnectViewModel: ObservableObject {
    var connectionState: EmergencyConnectState { get set }
    func connectButtonTapped()
    func appEnteredForeground()
}

class EmergencyConnectViewModelImpl: EmergencyConnectViewModel {

    @Published var connectionState: EmergencyConnectState = .disconnected

    private let vpnManager: VPNManager
    private let emergencyRepository: EmergencyRepository
    private let logger: FileLogger
    private var cancellables = Set<AnyCancellable>()
    private var ovpnInfoList: [OpenVPNConnectionInfo] = []

    init(vpnManager: VPNManager, emergencyRepository: EmergencyRepository, logger: FileLogger) {
        self.vpnManager = vpnManager
        self.emergencyRepository = emergencyRepository
        self.logger = logger

        observeVPNStateChanges()
    }

    private func observeVPNStateChanges() {
        vpnManager.getStatus()
            .toPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] state in
                guard let self = self else { return }

                self.logger.logD("EmergencyConnectViewModel", "VPN state changed to \(state)")

                switch state {
                case .connected:
                    self.connectionState = .connected
                case .connecting:
                    self.connectionState = .connecting
                case .disconnecting:
                    self.connectionState = .disconnecting
                default:
                    self.connectionState = .disconnected
                }
            })
            .store(in: &cancellables)
    }

    func appEnteredForeground() {
        vpnManager.connectionStateUpdatedTrigger.onNext(())
    }

    func connectButtonTapped() {
        guard connectionState != .disconnecting else { return }

        if connectionState == .connected || connectionState == .connecting {
            logger.logD("EmergencyConnectViewModel", "Disconnecting from emergency connect.")

            emergencyRepository.disconnect()
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                .store(in: &cancellables)
        } else {
            logger.logD("EmergencyConnectViewModel", "Getting emergency connect configuration.")

            Task { @MainActor in
                let config = await emergencyRepository.getConfig()
                self.ovpnInfoList.append(contentsOf: config)
                self.connect(using: config)
            }
        }
    }

    private func connect(using ovpnInfoList: [OpenVPNConnectionInfo]) {
        guard !ovpnInfoList.isEmpty else {
            logger.logE(Self.self, "Unable to get emergency connect configuration.")
            return
        }

        let firstAttempt = emergencyRepository.connect(configInfo: ovpnInfoList[0])
        let fallback: AnyPublisher<VPNConnectionState, Error> =
            ovpnInfoList.count > 1
                ? emergencyRepository.connect(configInfo: ovpnInfoList[1])
                : Fail(error: NSError(domain: "OpenVPN",
                                      code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "No backup OpenVPN config available."]))
                    .eraseToAnyPublisher()

        firstAttempt
            .catch { _ in fallback }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                switch completion {
                case .finished:
                    self.logger.logD("EmergencyConnectViewModel", "Successfully started OpenVPN.")
                case .failure(let error):
                    self.logger.logE("EmergencyConnectViewModel", "Failed to start OpenVPN: \(error.localizedDescription)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

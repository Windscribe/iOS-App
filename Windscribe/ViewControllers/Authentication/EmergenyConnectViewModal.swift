//
//  EmergenyConnectViewModal.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-02-29.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Foundation
import RxSwift

enum EmergencyConnectState {
    case disconnected, disconnecting, connecting, connected
}

protocol EmergenyConnectViewModal {
    var state: BehaviorSubject<EmergencyConnectState> { get }
    func connectButtonTapped()
    func appEnteredForeground()
}

class EmergencyConnectModalImpl: EmergenyConnectViewModal {
    let state = BehaviorSubject(value: EmergencyConnectState.disconnected)
    let vpnManager: VPNManager
    let emergencyRepository: EmergencyRepository
    let logger: FileLogger
    let disposeBag = DisposeBag()
    private var ovpnInfoList: [OpenVPNConnectionInfo] = []
    private var shouldRetry = false
    private var appCancellable = [AnyCancellable]()
    init(vpnManager: VPNManager, emergencyRepository: EmergencyRepository, logger: FileLogger) {
        self.vpnManager = vpnManager
        self.emergencyRepository = emergencyRepository
        self.logger = logger
        listenForVPNStateChange()
    }

    private func listenForVPNStateChange() {
        vpnManager.getStatus().subscribe(onNext: { [weak self] state in
            self?.logger.logD(EmergencyConnectModalImpl.self, "State changed to \(state)")
            switch state {
            case .connected:
                self?.state.onNext(EmergencyConnectState.connected)
            case .connecting:
                self?.state.onNext(.connecting)
            case .disconnecting:
                self?.state.onNext(.disconnecting)
            default:
                self?.state.onNext(.disconnected)
            }
        }).disposed(by: disposeBag)
    }

    func appEnteredForeground() {
        vpnManager.connectionStateUpdatedTrigger.onNext(())
    }

    func connectButtonTapped() {
        guard let state = try? state.value() else {
            return
        }
        if state == .disconnecting {
            return
        }
        if state == EmergencyConnectState.connected || state == .connecting {
            logger.logD(EmergencyConnectModalImpl.self, "Disconnecting from emergency connect.")
            emergencyRepository.disconnect().sink { _ in } receiveValue: { _ in }.store(in: &appCancellable)
        } else {
            Task { @MainActor in
                logger.logD(EmergencyConnectModalImpl.self, "Getting emergency connect configuration.")
                let ovpnInfo = await emergencyRepository.getConfig()
                self.ovpnInfoList.append(contentsOf: ovpnInfo)
                self.connect(ovpnInfoList: ovpnInfo)
            }
        }
    }

    private func connect(ovpnInfoList: [OpenVPNConnectionInfo]) {
        guard !ovpnInfoList.isEmpty else {
            logger.logE(self, "Unable to get emergency connect configuration.")
            return
        }
        let firstAttempt = emergencyRepository.connect(configInfo: ovpnInfoList[0])
        let secondAttempt: AnyPublisher<VPNConnectionState, Error> =
            ovpnInfoList.count > 1
                ? emergencyRepository.connect(configInfo: ovpnInfoList[1]).eraseToAnyPublisher()
                : Fail(error: NSError(domain: "OpenVPN", code: -1, userInfo: [NSLocalizedDescriptionKey: "No backup OpenVPN config available."])).eraseToAnyPublisher()
        firstAttempt.catch { _ in secondAttempt }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    self.logger.logD(self, "Successfully started OpenVPN.")
                case let .failure(error):
                    self.logger.logE(self, "Failed to start OpenVPN: \(error.localizedDescription)")
                }
            }, receiveValue: { _ in })
            .store(in: &appCancellable)
    }
}

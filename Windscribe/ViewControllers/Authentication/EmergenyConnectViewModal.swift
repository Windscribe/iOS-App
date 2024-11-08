//
//  EmergenyConnectViewModal.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-02-29.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
enum EmergencyConnectState {
    case disconnected, disconnecting, connecting, connected
}
protocol EmergenyConnectViewModal {
    var state: BehaviorSubject<EmergencyConnectState> { get }
    func connectButtonTapped()
}
class EmergencyConnectModalImpl: EmergenyConnectViewModal {
    let state =  BehaviorSubject(value: EmergencyConnectState.disconnected)
    let vpnManager: VPNManager
    let emergencyRepository: EmergencyRepository
    let logger: FileLogger
    let disposeBag = DisposeBag()
    private var ovpnInfoList: [OpenVPNConnectionInfo] = []
    private var shouldRetry = false
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
                self?.shouldRetry = false
            case .connecting:
                self?.state.onNext(.connecting)
            case .disconnecting:
                self?.state.onNext(.disconnecting)
            default:
                self?.state.onNext(.disconnected)
                self?.connect()
            }
        }).disposed(by: disposeBag)
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
            emergencyRepository.disconnect()
        } else {
            shouldRetry = true
            logger.logD(EmergencyConnectModalImpl.self, "Getting emergency connect info.")
            emergencyRepository.getConfig().subscribe(onSuccess: { ovpnInfo in
                self.ovpnInfoList.append(contentsOf: ovpnInfo)
                self.connect()
            }).disposed(by: disposeBag)
        }
    }

    private func connect() {
        if let ovpnInfo = ovpnInfoList.first, shouldRetry == true {
            ovpnInfoList.removeFirst()
            logger.logD(EmergencyConnectModalImpl.self, "Connecting to emergency connect. \(ovpnInfo)")
            DispatchQueue.main.async {
                self.emergencyRepository.connect(configInfo: ovpnInfo).subscribe(onCompleted: { [self] in
                    logger.logD(self, "Successfully started OpenVPN.")
                }, onError: { error in
                    if let error = error as? RepositoryError {
                        self.logger.logE(self, error.description)
                    }
                }).disposed(by: self.disposeBag)
            }
        }
    }
}

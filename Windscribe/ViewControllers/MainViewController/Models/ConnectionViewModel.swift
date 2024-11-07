//
//  ConnectionViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 07/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine

protocol ConnectionViewModelType {
    var connectedState: BehaviorSubject<ConnectionStateInfo> { get }
    var vpnManager: VPNManager { get }

    // Check State
    func isConnected() -> Bool
    func isConnecting() -> Bool
    func isDisconnected() -> Bool
    func isDisconnecting() -> Bool

    // Actions
    func setOutOfData()
    func enableConnection()
    func disableConnection()
}

class ConnectionViewModel: ConnectionViewModelType {
    let connectedState = BehaviorSubject<ConnectionStateInfo>(value: ConnectionStateInfo.defaultValue())

    private let disposeBag = DisposeBag()
    let vpnManager: VPNManager

    private var connectionTaskPublisher: AnyCancellable?

    init(vpnManager: VPNManager) {
        self.vpnManager = vpnManager
        vpnManager.vpnInfo.subscribe(onNext: { vpnInfo in
            guard let vpnInfo = vpnInfo else { return }
            self.connectedState.onNext(
                ConnectionStateInfo(state: ConnectionState.state(from: vpnInfo.status),
                                    isCustomConfigSelected: false,
                                    internetConnectionAvailable: false,
                                    connectedWifi: nil))
        }).disposed(by: disposeBag)
    }
}

extension ConnectionViewModel {
    func isConnected() -> Bool {
        (try? connectedState.value())?.state == .connected
    }

    func isConnecting() -> Bool {
        (try? connectedState.value())?.state == .connecting
    }

    func isDisconnected() -> Bool {
        (try? connectedState.value())?.state == .disconnected
    }

    func isDisconnecting() -> Bool {
        (try? connectedState.value())?.state == .disconnecting
    }

    func setOutOfData() {
        if isConnected(), !vpnManager.isCustomConfigSelected() {
            disableConnection()
        }
    }

    func enableConnection() {
        Task {
            let protocolPort = await vpnManager.getProtocolPort()
            let locationID = vpnManager.getLocationId()
            connectionTaskPublisher?.cancel()
            connectionTaskPublisher = vpnManager.connectFromViewModel(locationId: locationID, proto: protocolPort)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("Connection process completed.")
                    case let .failure(error):
                        print(error.localizedDescription)
                    }
                }, receiveValue: { state in
                    switch state {
                    case let .update(message):
                        print(message)
                    case let .validated(ip):
                        print(ip)
                    case let .vpn(status):
                        print(status)
                    default:
                        break
                    }
                })
        }
    }

    func disableConnection() {
        connectionTaskPublisher?.cancel()
        connectionTaskPublisher = vpnManager.disconnectFromViewModel().receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("disconnect finished")
                case let .failure(error):
                    print(error.localizedDescription)
                }
            } receiveValue: { state in
                switch state {
                case let .update(message):
                    print(message)
                case let .vpn(status):
                    print(status)
                default: ()
                }
            }
    }
}


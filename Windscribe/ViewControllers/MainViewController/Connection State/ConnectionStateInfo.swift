//
//  ConnectionStateInfo.swift
//  Windscribe
//
//  Created by Andre Fonseca on 07/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import NetworkExtension

enum ConnectionState {
    case connecting
    case connected
    case disconnecting
    case disconnected
    case test
    case automaticFailed

    static func state(from: NEVPNStatus) -> ConnectionState? {
        switch from {
        case .connected:
            return .connected
        case .disconnected:
            return .disconnected
        case .connecting:
            return .connecting
        case .disconnecting:
            return .disconnecting
        default:
            return nil
        }
    }
}

struct ConnectionStateInfo {
    let state: ConnectionState
    let isCustomConfigSelected: Bool
    let internetConnectionAvailable: Bool
    let customConfig: CustomConfigModel?
    let connectedWifi: WifiNetwork?

    static func defaultValue(startState: ConnectionState = .disconnected) -> ConnectionStateInfo {
        return ConnectionStateInfo(state: .disconnected, isCustomConfigSelected: false, internetConnectionAvailable: true, customConfig: nil, connectedWifi: nil)
    }
}

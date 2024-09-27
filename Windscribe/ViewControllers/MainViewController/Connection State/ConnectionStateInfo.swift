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

extension ConnectionState {
    var backgroundColor: UIColor {
        switch self {
        case .connected, .test: .connectedStartBlue
        case .connecting, .automaticFailed: .connectingStartBlue
        case .disconnecting: .disconnectedStartBlack
        case .disconnected: .lightMidnight
        }
    }
    var backgroundOpacity: Float { [.disconnecting].contains(self) ? 0.10 : 0.25 }
    var statusText: String {
        switch self {
        case .test: TextsAsset.Status.connectivityTest
        case .connected: TextsAsset.Status.on
        case .connecting: TextsAsset.Status.connecting
        case .disconnected, .disconnecting: TextsAsset.Status.off
        case .automaticFailed: ""
        }
    }
    var statusColor: UIColor {
        switch self {
        case .connected, .test: .seaGreen
        case .connecting: .lowGreen
        case .disconnecting, .disconnected: .white
        case .automaticFailed: .failedConnectionYellow
        }
    }
    var statusImage: String { self == .automaticFailed ? ImagesAsset.protocolFailed : ImagesAsset.connectionSpinner }
    var statusAlpha: CGFloat { [.connected, .test, .connecting, .automaticFailed].contains(self) ? 1.0 : 0.5 }
    var statusViewColor: UIColor { ([.disconnected, .disconnecting].contains(self) ? UIColor.white : .midnight).withAlphaComponent(0.25) }
    var preferredProtocolBadge: String {
        switch self {
        case .connected, .test: ImagesAsset.preferredProtocolBadgeOn
        case .connecting: ImagesAsset.preferredProtocolBadgeConnecting
        case .disconnecting, .disconnected, .automaticFailed: ImagesAsset.preferredProtocolBadgeOff
        }
    }
    var connectButtonRing: String {
        switch self {
        case .connected, .test: ImagesAsset.connectButtonRing
        case .connecting: ImagesAsset.connectingButtonRing
        case .disconnecting, .disconnected, .automaticFailed: ImagesAsset.failedConnectionButtonRing
        }
    }

    var connectButtonRingTv: String {
        switch self {
        case .connected, .test: ImagesAsset.TvAsset.connectedRing
        case .connecting: ImagesAsset.TvAsset.connectingRing
        case .disconnecting, .disconnected, .automaticFailed: ImagesAsset.TvAsset.disconnectedRing
        }
    }
    var connectButton: String { [.disconnected, .disconnecting].contains(self) ? ImagesAsset.disconnectedButton : ImagesAsset.connectButton }

    var connectButtonTV: String { [.disconnected, .disconnecting].contains(self) ? ImagesAsset.TvAsset.connectionButtonOff : ImagesAsset.TvAsset.connectionButtonOn }

    var connectButtonTvFocused: String { [.disconnected, .disconnecting].contains(self) ? ImagesAsset.TvAsset.connectionButtonOffFocused : ImagesAsset.TvAsset.connectionButtonOnFocused }
}

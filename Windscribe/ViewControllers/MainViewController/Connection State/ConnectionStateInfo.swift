//
//  ConnectionStateInfo.swift
//  Windscribe
//
//  Created by Andre Fonseca on 07/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RxSwift
import UIKit

enum ConnectionState {
    case connecting
    case connected
    case disconnecting
    case disconnected
    case testing
    case automaticFailed
    case invalid

    static func state(from: NEVPNStatus) -> ConnectionState {
        switch from {
        case .connected:
            return .connected
        case .disconnected:
            return .disconnected
        case .connecting:
            return .connecting
        case .disconnecting:
            return .disconnecting
        case .invalid:
            return .invalid
        default:
            return .disconnected
        }
    }
}

struct ConnectionStateInfo {
    let state: ConnectionState
    let isCustomConfigSelected: Bool
    let internetConnectionAvailable: Bool
    let connectedWifi: WifiNetwork?

    static func defaultValue(startState _: ConnectionState = .disconnected) -> ConnectionStateInfo {
        return ConnectionStateInfo(state: .disconnected, isCustomConfigSelected: false, internetConnectionAvailable: true, connectedWifi: nil)
    }
}

extension ConnectionState {
    var backgroundColor: UIColor {
        switch self {
        case .connected, .testing: .connectedStartBlue
        case .connecting, .automaticFailed: .connectingStartBlue
        case .disconnecting: .disconnectedStartBlack
        case .disconnected, .invalid: .lightMidnight
        }
    }

    var backgroundOpacity: Float { [.disconnecting].contains(self) ? 0.10 : 0.25 }
    var statusText: String {
        switch self {
        case .testing: TextsAsset.Status.connectivityTest
        case .connected: TextsAsset.Status.on
        case .connecting: TextsAsset.Status.connecting
        case .disconnected, .disconnecting, .invalid: TextsAsset.Status.off
        case .automaticFailed: ""
        }
    }

    var statusColor: UIColor {
        switch self {
        case .connected, .testing: .seaGreen
        case .automaticFailed: .failedConnectionYellow
        default: .white
        }
    }

    var statusViewColor: UIColor { statusColor.withAlphaComponent(0.1) }

    var statusImage: String { self == .automaticFailed ? ImagesAsset.protocolFailed : ImagesAsset.connectionSpinner }
    var statusAlpha: CGFloat { [.connected, .testing, .connecting, .automaticFailed].contains(self) ? 1.0 : 0.5 }
    var preferredProtocolBadge: String {
        switch self {
        case .connected, .testing: ImagesAsset.preferredProtocolBadgeOn
        case .connecting: ImagesAsset.preferredProtocolBadgeConnecting
        case .disconnecting, .disconnected, .automaticFailed, .invalid: ImagesAsset.preferredProtocolBadgeOff
        }
    }

    var connectButtonRing: String {
        switch self {
        case .connected, .testing: ImagesAsset.connectButtonRing
        case .connecting: ImagesAsset.connectingButtonRing
        case .disconnecting, .disconnected, .automaticFailed, .invalid: ImagesAsset.failedConnectionButtonRing
        }
    }

    var connectButtonRingColor: UIColor {
        switch self {
        case .connected: .seaGreen
        case .connecting, .testing: .whiteWithOpacity(opacity: 0.4)
        case .disconnecting, .disconnected, .automaticFailed, .invalid: .clear
        }
    }

    var connectButtonRingIsHidden: Bool {
        switch self {
        case .disconnected, .disconnecting, .invalid, .automaticFailed: true
        default: false
        }
    }

    var connectButtonRingTv: String {
        switch self {
        case .connected, .testing: ImagesAsset.TvAsset.connectedRing
        case .connecting: ImagesAsset.TvAsset.connectingRing
        case .disconnecting, .disconnected, .automaticFailed, .invalid: ImagesAsset.TvAsset.disconnectedRing
        }
    }

    var connectButton: String { [.disconnected, .disconnecting, .invalid].contains(self) ? ImagesAsset.disconnectedButton : ImagesAsset.connectButton }

    var connectButtonTV: String { [.disconnected, .disconnecting, .invalid].contains(self) ? ImagesAsset.TvAsset.connectionButtonOff : ImagesAsset.TvAsset.connectionButtonOn }

    var connectButtonTvFocused: String { [.disconnected, .disconnecting, .invalid].contains(self) ? ImagesAsset.TvAsset.connectionButtonOffFocused : ImagesAsset.TvAsset.connectionButtonOnFocused }
}

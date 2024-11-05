//
//  ConnectivityImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-09.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Foundation
import Network
import RxSwift

/// Manages network connectivity state using reachability and network path monitor.
class ConnectivityImpl: Connectivity {
    func getWifiSSID() -> String? {
        return try? network.value().name
    }

    private let logger: FileLogger
    /// Observe this subject to get network change events.
    let network: BehaviorSubject<AppNetwork> = BehaviorSubject(value: AppNetwork(.disconnected))
    private let monitor = NWPathMonitor()

    init(logger: FileLogger) {
        self.logger = logger
        registerNetworkPathMonitor()
    }

    /// Gets current network Infomation
    func getNetwork() -> AppNetwork {
        do {
            return try network.value()
        } catch {
            fatalError("Getting AppNetwork has erroed")
        }
    }

    func refreshNetwork() {
        refreshNetworkPathMonitor(path: monitor.currentPath)
    }

    /// Adds listener to network path monitor and builds network change events.
    private func registerNetworkPathMonitor() {
        let pathUpdateHandler = { (path: NWPath) in
            DispatchQueue.main.async {
                self.refreshNetworkPathMonitor(path: path)
            }
        }
        monitor.pathUpdateHandler = pathUpdateHandler
        let queue = DispatchQueue(label: "monitor queue", qos: .userInitiated)
        monitor.start(queue: queue)
    }

    private func refreshNetworkPathMonitor(path: NWPath) {
        WSNet.instance().setIsConnectedToVpnState(isVPN(path: path))
        WSNet.instance().setConnectivityState(path.status == .satisfied)
        let networkType = getNetworkType(path: path)
        getNetworkName(networkType: networkType) { ssid in
            let appNetwork = AppNetwork(self.getNetworkStatus(path: path), networkType: networkType, name: ssid, isVPN: self.isVPN(path: path))
            self.logger.logI(self, "\(appNetwork.description)")
            self.network.onNext(appNetwork)
            NotificationCenter.default.post(Notification(name: Notifications.reachabilityChanged))
        }
    }

    func awaitNetwork(maxTime: Double) async throws {
        let timeout: TimeInterval = maxTime
        let startTime = Date()
        while getNetwork().status != .connected {
            if Date().timeIntervalSince(startTime) > timeout {
                return
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    /// Returns network status from NWPath
    private func getNetworkStatus(path: NWPath) -> NetworkStatus {
        switch path.status {
        case .satisfied:
            return .connected
        case .unsatisfied:
            return .disconnected
        // Changes to .satisfied once VPN connection is restored or kill switch is turned off.
        case .requiresConnection:
            return .requiresVPN
        @unknown default:
            return .connected
        }
    }

    /// Returns network type from NWPath
    private func getNetworkType(path: NWPath) -> NetworkType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else {
            if path.availableInterfaces.filter({ $0.type == .cellular }).first?.type == .cellular {
                return .cellular
            } else {
                return .none
            }
        }
    }

    /// Returns  if VPN is active.
    /// - Note: This function solely relies on network interface names so may be not as reliable as checking with vpn manager.
    private func isVPN(path: NWPath) -> Bool {
        return path.availableInterfaces.first { i in
            i.name.starts(with: "ipsec") || i.name.starts(with: "utun")
        }.map { _ in
            true
        } ?? false
    }

    /// Returns  optional network carier name or SSID for network type
    private func getNetworkName(networkType: NetworkType, completion: @escaping (String?) -> Void) {
        switch networkType {
        case .cellular:
            completion(getCellularNetworkName())
        case .wifi:
            getSsidFromNeHotspotHelper { ssid in
                completion(ssid)
            }
        case .none:
            completion(nil)
        }
    }

    /// Returns carrier name for cellular network
    ///  - Note: This api was depcreated in iOS 16.0 and returns "Cellular"
    private func getCellularNetworkName() -> String {
        return "Cellular"
    }

    func internetConnectionAvailable() -> Bool {
        return (try? network.value().status == .connected) != nil
    }
}

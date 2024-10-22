//
//  ConnectivityImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-09.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Network
import RxSwift
import SystemConfiguration.CaptiveNetwork

/// Manages network connectivity state using reachability and network path monitor.
class ConnectivityImpl: Connectivity {
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
        WSNet.instance().setIsConnectedToVpnState(self.isVPN(path: path))
        WSNet.instance().setConnectivityState(path.status == .satisfied)
        let networkType = self.getNetworkType(path: path)
        getNetworkName(networkType: networkType) { ssid in
            let appNetwork = AppNetwork(self.getNetworkStatus(path: path), networkType: networkType, name: ssid, isVPN: self.isVPN(path: path))
            self.network.onNext(appNetwork)
            NotificationCenter.default.post(Notification(name: Notifications.reachabilityChanged))
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
    func getNetworkName(networkType: NetworkType, completion: @escaping (String?) -> Void) {
        switch networkType {
        case .cellular:
            completion(getCellularNetworkName())
        case .wifi:
            getSsidFromNeHotspotHelper { [weak self] ssid in
                if let ssid = ssid {
                    completion(ssid)
                } else {
                    completion(self?.getWifiSSID())
                }
            }
        case .none:
            completion(nil)
        }
    }

    /// Returns optional Wifi SSID for current network.
    func getWifiSSID() -> String? {
        if getNetworkType(path: monitor.currentPath) == .cellular {
            return getCellularNetworkName()
        }
        var interface = [String: Any]()
#if os(iOS)
        if let interfaces = CNCopySupportedInterfaces() {
            for i in 0 ..< CFArrayGetCount(interfaces) {
                let interfaceName = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                guard let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString) else {
                    let ssid = interface["SSID"] as? String
                    return ssid
                }
                guard let interfaceData = unsafeInterfaceData as? [String: Any] else {
                    return interface["SSID"] as? String
                }
                interface = interfaceData
            }
        }
        if let SSID = interface["SSID"] as? String {
            return SSID
        }
#endif
        return nil
    }

    /// Returns carrier name for cellular network
    ///  - Note: This api was depcreated in iOS 16.0 and returns "Cellular"
    private func getCellularNetworkName() -> String {
        return "Cellular"
    }

    func internetConnectionAvailable() -> Bool {
        return ((try? network.value().status == .connected) != nil)
    }
}

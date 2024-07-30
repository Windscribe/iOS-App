//
//  ConnectionManager.swift
//  Windscribe
//
//  Created by Thomas on 14/10/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RxSwift
import Swinject

class ConnectionManager: ConnectionManagerV2 {
    private var logger: FileLogger
    private let disposeBag = DisposeBag()
    private var connectivity: Connectivity
    private var localDatabase: LocalDatabase
    private var securedNetwork: SecuredNetworkRepository
    private var preferences: Preferences
    static var shared = Assembler.resolve(ConnectionManagerV2.self)
    // MARK: - Properties
    /// Default protocol
    let defaultProtocol = ProtocolPort(wireGuard, DefaultValues.port)
    /// Provides concurrent access to protocol list.
    private let accessQueue = DispatchQueue(label: "connectionManagerAccessQueve", attributes: .concurrent)
    /// List of Protocols in ordered by priority
    private(set) var protocolsToConnectList: [DisplayProtocolPort] = []
    /// App selected this protocol automatcally or user selected it
    private var userSelected: ProtocolPort?
    /// Timer to reset good protocol
    private var scheduledTimer: Timer!
    /// Last successful protocol
    var goodProtocol: ProtocolPort?
    var resetGoodProtocolTime: Date?
    var failoverNetworkName: NetworkType = NetworkType.none
    var manualProtocol: String = DefaultValues.protocol
    var manualPort: String = DefaultValues.port
    var connectionMode = DefaultValues.connectionMode
    init(logger: FileLogger, connectivity: Connectivity, preferences: Preferences, securedNetwork: SecuredNetworkRepository, localDatabase: LocalDatabase) {
        self.logger = logger
        self.connectivity = connectivity
        self.preferences = preferences
        self.securedNetwork = securedNetwork
        self.localDatabase = localDatabase
        logger.logI(self, "Starting connection manager.")
        loadProtocols(shouldReset: true) { [weak self] list in
            self?.protocolsToConnectList = list
        }
        bindData()
    }

    func bindData() {
        preferences.getConnectionMode().subscribe( onNext: { [weak self] mode in
            self?.connectionMode = mode ?? DefaultValues.connectionMode
        }).disposed(by: disposeBag)
        preferences.getSelectedProtocol().subscribe( onNext: { [weak self] proto in
            self?.manualProtocol = proto ?? DefaultValues.protocol
        }).disposed(by: disposeBag)
        preferences.getSelectedPort().subscribe( onNext: { [weak self] port in
            self?.manualPort = port ?? DefaultValues.port
        }).disposed(by: disposeBag)
    }
    // MARK: - Actions
    /// Load protocols
    /// change their priority based on user settings.
    /// append port
    /// Priority order [Connected, User selected, Preferred, Manual, Good, Failed]
    func loadProtocols(shouldReset: Bool, comletion: @escaping ([DisplayProtocolPort]) -> Void) {
        if failoverNetworkName != .none && failoverNetworkName != connectivity.getNetwork().networkType {
            goodProtocol = nil
            userSelected = nil
            protocolsToConnectList.removeAll()
        }
        failoverNetworkName = connectivity.getNetwork().networkType
        if shouldReset {
            getProtocolList()
        }
        // Save all failed protocols
        let failedProtocols = protocolsToConnectList.filter { list in list.viewType == .fail }
        // Reset all protocol type to normal
        protocolsToConnectList.first { displayPortAndProtocol in
            displayPortAndProtocol.viewType == .connected
        }?.viewType = .normal

        if let goodProtocol = goodProtocol {
            appendPort(proto: goodProtocol.protocolName, port: goodProtocol.portName)
            setPriority(proto: goodProtocol.protocolName, type: .normal)
        }

        if connectionMode == Fields.Values.manual {
            logger.logD(self,  "Manual protocol : \(manualProtocol)")
            appendPort(proto: manualProtocol, port: manualPort)
            setPriority(proto: manualProtocol, type: .normal)
        }
        WifiManager.shared.saveCurrentWifiNetworks()
        if securedNetwork.getCurrentNetwork()?.preferredProtocolStatus == true {
            let preferredProto = securedNetwork.getCurrentNetwork()?.preferredProtocol ?? defaultProtocol.protocolName
            let preferredPort = securedNetwork.getCurrentNetwork()?.preferredPort ?? defaultProtocol.portName
            appendPort(proto: preferredProto, port: preferredPort)
            setPriority(proto: preferredProto, type: .normal)
        }

        if let userSelected = userSelected {
            appendPort(proto: userSelected.protocolName, port: userSelected.portName)
            setPriority(proto: userSelected.protocolName, type: .normal)
        }

        failedProtocols.forEach { displayProtocol in
            logger.logD(self, "Failed: \(displayProtocol.protocolPort.protocolName)")
            setPriority(proto: displayProtocol.protocolPort.protocolName, type: .fail)
        }

        VPNManager.shared.getVPNConnectionInfo { [self] info in
            if let info = info, info.status == NEVPNStatus.connected {
                appendPort(proto: info.selectedProtocol, port: info.selectedPort)
                setPriority(proto: info.selectedProtocol, type: .connected)
            } else {
                protocolsToConnectList.first?.viewType = .nextUp
            }
            let log = protocolsToConnectList.map { "\($0.protocolPort.protocolName) \($0.protocolPort.portName) \($0.viewType)"}.joined(separator: ", ")
            logger.logI(self, log)
            comletion(protocolsToConnectList)
        }
    }

    /// Next protocol to connect.
    func getNextProtocol() -> ProtocolPort {
        accessQueue.sync {
            return protocolsToConnectList.first.map { displayPort in
                displayPort.protocolPort
            } ?? defaultProtocol
        }
    }

    /// VPN state changed.
    func onConnectStateChange(state: NEVPNStatus) {
        accessQueue.async { [self] in
            userSelected = nil
            logger.logI(self, "Connection state changed to \(state).")
            if state == .connected {
                protocolsToConnectList.first { $0.viewType == .nextUp
                }?.viewType = .connected
                protocolsToConnectList.filter {$0.viewType == .nextUp}.forEach { $0.viewType = .normal }
            }
            if state == .disconnected {
                protocolsToConnectList.filter {$0.viewType == .nextUp }.forEach {$0.viewType = .normal}
                protocolsToConnectList.first { $0.viewType == .connected
                }?.viewType = .normal
            }
        }
    }

    /// User/App selected this protocol to connect.
    func onUserSelectProtocol(proto: ProtocolPort) {
        VPNManager.shared.successfullProtocolChange = true
        logger.logI(self, "User selected \(proto) to connect.")
        userSelected = proto
        setPriority(proto: proto.portName)
    }

    /// Resetting good Protocol after 12 hours(43200 seconds).
    @objc func resetGoodProtocol() {
        if goodProtocol != nil {
            let diff = Date().timeIntervalSince(resetGoodProtocolTime ?? Date())
            if diff >= 43200 {
                logger.logI(self, "Resetting good Protocol after 12 hours.")
                reset { _ in }
                scheduledTimer.invalidate()
            }
        }
    }

    /// Current protocol failed to connect, lower its priority.
    func onProtocolFail(completion: @escaping (Bool) -> Void) {
        userSelected = nil
        return accessQueue.sync { [self] in
            let failedProtocol = getNextProtocol()
            logger.logI(self, "\(failedProtocol.protocolName) failed to connect.")
            setPriority(proto: failedProtocol.protocolName, type: .fail)
            if protocolsToConnectList.filter({ $0.viewType == .normal}).count <= 0 {
                logger.logI(self, "No more protocol left to connect.")
                reset(completion: completion)
            } else {
                completion(false)
            }
        }
    }

    func scheduleTimer() {
        scheduledTimer = Timer.scheduledTimer(timeInterval: 3600, target: self, selector: #selector(resetGoodProtocol), userInfo: nil, repeats: true)
    }

    func saveCurrentWifiNetworks() {
        WifiManager.shared.saveCurrentWifiNetworks()
    }

    // MARK: - Helper
    private func getAppSupportedProtocol() -> [String] {
        return TextsAsset.General.protocols
    }

    private func reset(completion: @escaping (Bool) -> Void) {
        userSelected = nil
        goodProtocol = nil
        protocolsToConnectList.removeAll()
        loadProtocols(shouldReset: true) {  _ in
            completion(true)
        }
    }

    private func setPriority(proto: String, type: ProtocolViewType = .normal) {
        accessQueue.sync {
            var copy = protocolsToConnectList
            if let index = copy.firstIndex(where: { displayPortAndProtocol in
                displayPortAndProtocol.protocolPort.protocolName == proto
            }) {
                let item = copy[index]
                item.viewType = type
                copy.remove(at: index)
                if type == .connected || type == .normal || type == .nextUp {
                    copy.insert(item, at: 0)
                } else {
                    copy.append(item)
                }
            }
            protocolsToConnectList = copy
        }
    }

    private func appendPort(proto: String, port: String) {
        protocolsToConnectList.first { $0.protocolPort.protocolName == proto }?.protocolPort.portName = port
    }

    /// Protocol list in app preferred order.
    private func getProtocolList() {
        let listProtocol = getAppSupportedProtocol()
        var lstConnection: [ProtocolPort] = []
        for protocolName in listProtocol {
            if let lstPort = localDatabase.getPorts(protocolType: protocolName),
               let firstPort = lstPort.first {
                lstConnection.append((protocolName, firstPort))
            }
        }
        protocolsToConnectList = lstConnection.map { DisplayProtocolPort(protocolPort: $0, viewType: .normal) }
    }
}

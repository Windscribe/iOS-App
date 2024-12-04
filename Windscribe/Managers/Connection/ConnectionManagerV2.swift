//
//  ConnectionManagerV2.swift
//  Windscribe
//
//  Created by Bushra Sagir on 09/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RxSwift

protocol ConnectionManagerV2 {
    var goodProtocol: ProtocolPort? { get set }
    var resetGoodProtocolTime: Date? { get set }

    var currentProtocolSubject: BehaviorSubject<ProtocolPort?> { get }
    var connectionProtocolSubject: BehaviorSubject<ProtocolPort?> { get }

    func refreshProtocols(shouldReset: Bool, shouldUpdate: Bool, shouldReconnect: Bool) async
    func getRefreshedProtocols() async -> [DisplayProtocolPort]
    func getNextProtocol() async -> ProtocolPort
    func getProtocol() -> ProtocolPort
    func onProtocolFail() async -> Bool
    func onUserSelectProtocol(proto: ProtocolPort)
    func resetGoodProtocol()
    func onConnectStateChange(state: NEVPNStatus)
    func scheduleTimer()
    func saveCurrentWifiNetworks()
    func nextSelecteProtocol() -> ProtocolPort
}

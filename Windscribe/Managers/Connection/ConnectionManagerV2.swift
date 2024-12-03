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

    var protocolListUpdatedTrigger: PublishSubject<Void> { get }

    func refreshProtocols(shouldReset: Bool, shouldUpdate: Bool) async
    func getRefreshedProtocols() async -> [DisplayProtocolPort]
    func getNextProtocol() async -> ProtocolPort
    func getNextProtocol(shouldReset: Bool) async -> ProtocolPort
    func onProtocolFail() async -> Bool
    func onUserSelectProtocol(proto: ProtocolPort)
    func resetGoodProtocol()
    func onConnectStateChange(state: NEVPNStatus)
    func scheduleTimer()
    func saveCurrentWifiNetworks()
}

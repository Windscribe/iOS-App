//
//  ConnectionManagerV2.swift
//  Windscribe
//
//  Created by Bushra Sagir on 09/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
protocol ConnectionManagerV2 {
    var goodProtocol: ProtocolPort? {get set}
    var resetGoodProtocolTime: Date? {get set}
    func loadProtocols(shouldReset: Bool, comletion: @escaping ([DisplayProtocolPort]) -> Void)
    func onProtocolFail(completion: @escaping (Bool) -> Void)
    func onUserSelectProtocol(proto: ProtocolPort)
    func getNextProtocol() -> ProtocolPort
    func resetGoodProtocol()
    func onConnectStateChange(state: NEVPNStatus)
    func scheduleTimer()
    func saveCurrentWifiNetworks()
    func getNextProtocol(shouldReset: Bool) async throws -> ProtocolPort
}

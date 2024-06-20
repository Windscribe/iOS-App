//
//  SecuredNetworkRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-10.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
protocol SecuredNetworkRepository {
    var networks: BehaviorSubject<[WifiNetwork]> { get }
    func addNetwork(status: Bool, protocolType: String, port: String, preferredProtocol: String, preferredPort: String)
    func getCurrentNetwork() -> WifiNetwork?
    func getOtherNetworks() -> [WifiNetwork]?
    func removeNetwork(network: WifiNetwork)
    func setNetworkPreferredProtocol(network: WifiNetwork)
    func setNetworkDontAskAgainForPreferredProtocol(network: WifiNetwork)
    func incrementNetworkDismissCount(network: WifiNetwork)
}

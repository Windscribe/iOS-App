//
//  Connectivity.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-09.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
protocol Connectivity {
    var network: BehaviorSubject<AppNetwork> { get }
    func getNetwork() -> AppNetwork
    func refreshNetwork()
    func internetConnectionAvailable() -> Bool
    func getWifiSSID() -> String?
    func awaitNetwork(maxTime: Double) async throws
}

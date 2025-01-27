//
//  WireguardAPIManager.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol WireguardAPIManager {
    func getSession() -> Single<Session>
    func wgConfigInit(clientPublicKey: String, deleteOldestKey: Bool) -> RxSwift.Single<DynamicWireGuardConfig>
    func wgConfigConnect(clientPublicKey: String, hostname: String, deviceId: String) -> RxSwift.Single<DynamicWireGuardConnect>
}

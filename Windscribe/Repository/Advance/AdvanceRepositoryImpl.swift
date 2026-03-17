//
//  AdvanceRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-04-05.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class AdvanceRepositoryImpl: AdvanceRepository {
    private let preferences: Preferences
    private let vpnStateRepository: VPNStateRepository!

    init(preferences: Preferences,
         vpnStateRepository: VPNStateRepository) {
        self.preferences = preferences
        self.vpnStateRepository = vpnStateRepository
    }

    func getForcedServer() -> String? {
        return getValue(key: wsForceNode)
    }

    func getPingType() -> Int32 {
        let pingType = getValue(key: wsUsesICMPPings) ?? "false"
        return pingType == "true" ? 1 : 0
    }

    private func getValue(key: String) -> String? {
        return preferences.getAdvanceParams().splitToArray(separator: "\n").first { keyValue in
            let pair = keyValue.splitToArray(separator: "=")
            return pair.count == 2 && pair[0] == key
        }?.splitToArray(separator: "=")
            .dropFirst()
            .joined(separator: "=")
    }
}

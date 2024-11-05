//
//  AdvanceRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-04-05.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RxSwift

class AdvanceRepositoryImpl: AdvanceRepository {
    private let preferences: Preferences
    private let vpnManager: VPNManager
    private let disposeBag = DisposeBag()
    init(preferences: Preferences, vpnManager: VPNManager) {
        self.preferences = preferences
        self.vpnManager = vpnManager
    }

    func getCountryOverride() -> String? {
        let countryCode = getValue(key: wsServerOverrride)
        let overriddenCountryCode = preferences.getCountryOverride()
        let isConnectedVPN = vpnManager.isConnected()
        return if let countryCode = countryCode {
            if countryCode == ignoreCountryOverride {
                ignoreCountryCode
            } else {
                countryCode
            }
        } else if overriddenCountryCode == nil && isConnectedVPN {
            ignoreCountryCode
        } else {
            overriddenCountryCode
        }
    }

    func getForcedNode() -> String? {
        return getValue(key: wsForceNode)
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

//
//  WSNetInstanceType.swift
//  Windscribe
//
//  Created by Windscribe on 2026-06-23.
//  Copyright © 2026 Windscribe. All rights reserved.
//

protocol WSNetInstanceType {
    func setIsConnectedToVpnState(_ isConnected: Bool)
    func currentPersistentSettings() -> String
}

extension WSNet: WSNetInstanceType {}

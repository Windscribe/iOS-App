//
//  LocalPingManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

protocol LocalPingManager {
    func ping(_ ip: String,
              hostname: String,
              pingType: Int32,
              callback: @escaping (String, Bool, Int32, Bool) -> Void)
}

class LocalPingManagerImpl: LocalPingManager {
    private let pingManager: WSNetPingManager

    init(pingManager: WSNetPingManager) {
        self.pingManager = pingManager
    }

    func ping(_ ip: String,
              hostname: String,
              pingType: Int32,
              callback: @escaping (String, Bool, Int32, Bool) -> Void) {
        pingManager.ping(ip, hostname: hostname, pingType: pingType, callback: callback)
    }
}

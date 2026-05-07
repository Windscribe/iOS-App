//
//  LocalPingManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

protocol LocalPingManager {
    func ping(_ ip: String,
              hostname: String,
              pingType: Int32) async -> (time: Int32, success: Bool)
}

class LocalPingManagerImpl: LocalPingManager {
    private let pingManager: WSNetPingManagerType
    private let serialQueue = DispatchQueue(label: "com.windscribe.ping.serial", qos: .userInitiated)

    init(pingManager: WSNetPingManagerType) {
        self.pingManager = pingManager
    }

    func ping(_ ip: String,
              hostname: String,
              pingType: Int32) async -> (time: Int32, success: Bool) {
        // Validate inputs before passing to C++ layer
        guard !ip.isEmpty, !hostname.isEmpty else {
            return (-1, false)
        }

        return await withCheckedContinuation { (continuation: CheckedContinuation<(time: Int32, success: Bool), Never>) in
            // Capture values to avoid closure capture issues with C++ bridge
            let capturedIP = ip
            let capturedHost = hostname
            let capturedPingType = pingType
            self.pingManager.ping(capturedIP, hostname: capturedHost, pingType: capturedPingType) { _, _, time, success in
                continuation.resume(returning: (time: time, success: success))
            }
        }
    }
}

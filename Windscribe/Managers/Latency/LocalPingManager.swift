//
//  LocalPingManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

// MARK: - Local Ping Manager

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

        let request = PingRequest()
        return await withTaskCancellationHandler(operation: {
            guard !Task.isCancelled else { return (-1, false) }

            return await withCheckedContinuation { continuation in
                request.setContinuation(continuation)
                guard !Task.isCancelled else {
                    request.cancel()
                    return
                }

                let callback = self.pingManager.ping(ip, hostname: hostname, pingType: pingType) { _, _, time, success in
                    request.complete(time: time, success: success)
                }
                request.setCallback(callback)
            }
        }, onCancel: {
            request.cancel()
        })
    }
}

// MARK: - Ping Request

// All mutable state is protected by lock.
private final class PingRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<(time: Int32, success: Bool), Never>?
    private var callback: WSNetCancelableCallback?
    private var finished = false

    func setContinuation(_ continuation: CheckedContinuation<(time: Int32, success: Bool), Never>) {
        lock.lock()
        guard !finished else {
            lock.unlock()
            continuation.resume(returning: (-1, false))
            return
        }
        self.continuation = continuation
        lock.unlock()
    }

    func setCallback(_ callback: WSNetCancelableCallback) {
        lock.lock()
        guard !finished else {
            lock.unlock()
            callback.cancel()
            return
        }
        self.callback = callback
        lock.unlock()
    }

    func complete(time: Int32, success: Bool) {
        finish(time: time, success: success)
    }

    func cancel() {
        finish(time: -1)
    }

    private func finish(time: Int32, success: Bool = false) {
        lock.lock()
        guard !finished else {
            lock.unlock()
            return
        }
        finished = true
        let continuation = self.continuation
        let callback = self.callback
        self.continuation = nil
        self.callback = nil
        lock.unlock()

        if time == -1 {
            callback?.cancel()
        }
        continuation?.resume(returning: (time: time, success: success))
    }
}

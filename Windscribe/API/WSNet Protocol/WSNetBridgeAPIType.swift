//
//  WSNetBridgeAPIType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 19/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

protocol WSNetBridgeAPIType {
    func setConnectedState(_ connected: Bool)
    func setIgnoreSslErrors(_ ignore: Bool)
    func hasSessionToken() -> Bool
    func setApiAvailableCallback(_ callback: @escaping (Bool) -> Void)
    func setCurrentHost(_ host: String)

    func rotateIp() async throws -> (Int32, String)
    func pinIp(ip: String) async throws -> (Int32, String)
}

extension WSNetBridgeAPI: WSNetBridgeAPIType {
    func rotateIp() async throws -> (Int32, String) {
        return try await callAPIWithTimeout { completion in
            self.rotateIp(completion)
        }
    }

    func pinIp(ip: String) async throws -> (Int32, String) {
        return try await callAPIWithTimeout { completion in
            self.pinIp(ip, callback: completion)
        }
    }

    private func callAPIWithTimeout(apiCall: @escaping (@escaping (Int32, String) -> Void) -> WSNetCancelableCallback?) async throws -> (Int32, String)  {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Int32, String), Error>) in
            var hasResumed = false
            var cancelableCallback: WSNetCancelableCallback?

            // Start timeout task
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                if !hasResumed {
                    hasResumed = true
                    cancelableCallback?.cancel()
                    let wsnetError = WSNetErrors.bridgeAPIError.error ?? Errors.noResponse
                    continuation.resume(throwing: wsnetError)
                }
            }

            // Start API call
            cancelableCallback = apiCall { statusCode, message in
                if !hasResumed {
                    hasResumed = true
                    timeoutTask.cancel()
                    continuation.resume(returning: (statusCode, message))
                }
            }
        }
    }
}

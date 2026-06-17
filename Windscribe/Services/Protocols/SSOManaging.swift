//
//  SSOManaging.swift
//  Windscribe
//
//  Created by Andre Fonseca on 10/06/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@preconcurrency import Combine

protocol SSOManaging: Sendable {
    func getSession() async throws
    func reauthenticate() async throws -> String
}

/// Adapter wrapping the legacy `UserDataRepository`.
final class LegacySSOManager: SSOManaging, Sendable {
    private let legacy: LegacySSOManaging
    private var cancellables = Set<AnyCancellable>()

    init(legacy: LegacySSOManaging) {
        self.legacy = legacy
    }

    func getSession() async throws {
        try await withCheckedThrowingContinuation { continuation in
            legacy.getSession()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { _ in
                    continuation.resume()
                })
                .store(in: &cancellables)
        }
    }

    func reauthenticate() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            legacy.reauthenticate()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { token in
                    continuation.resume(returning: token)
                })
                .store(in: &cancellables)
        }
    }
}

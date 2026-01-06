//
//  IPRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import NetworkExtension
import Swinject
import Combine

enum IPState: Equatable {
    case available(String), updating, unavailable
}
class IPRepositoryImpl: IPRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase  // Kept for migration from older versions
    private let preferences: Preferences
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    private var wasObserved = false
    private var cancellables = Set<AnyCancellable>()

    let ipState: BehaviorSubject<IPState?>
    let currentIp: CurrentValueSubject<String?, Never>

    init(apiManager: APIManager, localDatabase: LocalDatabase, preferences: Preferences, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.preferences = preferences
        self.logger = logger

        // Migration: Check if IP exists in Realm (from older app versions)
        // If yes, migrate it to Preferences for future use
        if let realmIp = localDatabase.getIpSync() {
            logger.logI("IPRepositoryImpl", "Migrating IP from Realm to Preferences: \(realmIp.userIp)")
            preferences.saveCurrentIpAddress(ip: realmIp.userIp)
        }

        // Load cached IP from Preferences and initialize BehaviorSubject with correct initial state
        // This ensures subscribers immediately get the correct value without race conditions
        let initialState: IPState?
        if let cachedIp = preferences.getCurrentIpAddress() {
            logger.logI("IPRepositoryImpl", "Loaded cached IP from Preferences: \(cachedIp)")
            initialState = .available(cachedIp)
            self.currentIp = CurrentValueSubject<String?, Never>(cachedIp)
            wasObserved = true
        } else {
            logger.logI("IPRepositoryImpl", "No cached IP found in Preferences")
            initialState = .unavailable
            self.currentIp = CurrentValueSubject<String?, Never>(nil)
        }

        self.ipState = BehaviorSubject<IPState?>(value: initialState)

        // Set up async observation for Preferences changes
        load()
    }

    /// Observes Preferences changes for IP updates
    private func load() {
        preferences.getCurrentIpAddressObservable()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ipAddress in
                guard let self = self else { return }
                self.wasObserved = true
                if let ipAddress = ipAddress {
                    self.updateState(.available(ipAddress))
                    self.currentIp.send(ipAddress)
                } else {
                    self.updateState(.unavailable)
                }
            }
            .store(in: &cancellables)
    }

    /// Fetches the current IP from the API and updates Preferences
    func getIp() async throws {
        let lastState = try? ipState.value()

        // Only show .updating if we don't have a valid IP already
        // This keeps the cached IP visible while fetching fresh data
        if case .available(_)? = lastState {
            // Keep showing cached IP while updating in background
            logger.logI("IPRepositoryImpl", "Fetching fresh IP while keeping cached IP visible")
        } else {
            updateState(.updating)
        }

        do {
            let ipAddress = try await apiManager.getIp()
            if !wasObserved {
                await MainActor.run {
                    load()
                    updateState(.available(ipAddress))
                }
            }

            logger.logI("IPRepositoryImpl", "IP was refreshed with: \(ipAddress)")
            currentIp.send(ipAddress)
            preferences.saveCurrentIpAddress(ip: ipAddress)
        } catch {
            await MainActor.run {
                updateState(lastState)
            }
            throw error
        }
    }

    private func updateState(_ ipState: IPState?) {
        DispatchQueue.main.async {
            self.ipState.onNext(ipState)
        }
    }
}

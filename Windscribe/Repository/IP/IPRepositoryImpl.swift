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
    case available(MyIP), updating, unavailable
}
class IPRepositoryImpl: IPRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    private var wasObserved = false
    private var cancellables = Set<AnyCancellable>()

    let ipState: BehaviorSubject<IPState?>
    let currentIp: CurrentValueSubject<String?, Never>

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger

        // Load cached IP synchronously and initialize BehaviorSubject with correct initial state
        // This ensures subscribers immediately get the correct value without race conditions
        let initialState: IPState?
        if let cachedIp = localDatabase.getIpSync() {
            logger.logI("IPRepositoryImpl", "Loaded cached IP synchronously: \(cachedIp.userIp)")
            initialState = .available(cachedIp)
            self.currentIp = CurrentValueSubject<String?, Never>(cachedIp.userIp)
            wasObserved = true
        } else {
            logger.logI("IPRepositoryImpl", "No cached IP found in database")
            initialState = .unavailable
            self.currentIp = CurrentValueSubject<String?, Never>(nil)
        }

        self.ipState = BehaviorSubject<IPState?>(value: initialState)

        // Set up async observation for database changes
        load()
    }

    /// Observes database changes for IP updates
    private func load() {
        localDatabase.getIp()
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] myIp in
                guard let self = self else { return }
                self.wasObserved = true
                if let myIp = myIp {
                    self.updateState(.available(myIp))
                    self.currentIp.send(myIp.userIp)
                } else {
                    self.updateState(.unavailable)
                }
            }, onError: { [weak self] error in
                self?.updateState(.unavailable)
                self?.logger.logE("ip", "Failed to load IP from database: \(error)")
            }).disposed(by: disposeBag)
    }

    /// Fetches the current IP from the API and updates the local database
    func getIp() -> Single<Void> {
        let lastState = try? ipState.value()

        // Only show .updating if we don't have a valid IP already
        // This keeps the cached IP visible while fetching fresh data
        if case .available(_)? = lastState {
            // Keep showing cached IP while updating in background
            logger.logI("IPRepositoryImpl", "Fetching fresh IP while keeping cached IP visible")
        } else {
            updateState(.updating)
        }

        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.success(()))
                    return
                }

                do {
                    let data = try await self.apiManager.getIp()
                    if !self.wasObserved {
                        await MainActor.run {
                            self.load()
                            self.updateState(.available(data))
                        }
                    }

                    self.logger.logI("IPRepositoryImpl", "Ip was refreshed with: \(data.userIp) Windscribe IP: \(data.isOurIp)")
                    currentIp.send(data.userIp)
                    _ = self.localDatabase.saveIp(myip: data)

                    single(.success(()))
                } catch {
                    await MainActor.run {
                        self.updateState(lastState)
                        single(.failure(error))
                    }
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func updateState(_ ipState: IPState?) {
        DispatchQueue.main.async {
            self.ipState.onNext(ipState)
        }
    }
}

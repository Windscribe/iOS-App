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

enum IPState: Equatable {
    case available(MyIP), updating, unavailable
}
class IPRepositoryImpl: IPRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    private var wasObserved = false
    let ipState: BehaviorSubject<IPState?> = BehaviorSubject(value: nil)

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
        load()
    }

    /// Loads the last known IP from the local database
    private func load() {
        localDatabase.getIp().observe(on:MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] data in
                self?.wasObserved = true
                if let data = data {
                    self?.updateState(.available(data))
                } else {
                    self?.updateState(.unavailable)
                }
            }, onError: { [weak self] error in
                self?.updateState(.unavailable)
                self?.logger.logE("ip", "Failed to load IP from database: \(error)")
            }).disposed(by: disposeBag)
    }

    /// Fetches the current IP from the API and updates the local database
    func getIp() -> Single<Void> {
        let lastState = try? ipState.value()
        updateState(.updating)

        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.success(()))
                    return
                }

                do {
                    let data = try await self.apiManager.getIp()

                    await MainActor.run {
                        if !self.wasObserved {
                            self.load()
                            self.updateState(.available(data))
                        }

                        self.logger.logI("IPRepositoryImpl", "Ip was refreshed with: \(data.userIp) Windscribe IP: \(data.isOurIp)")
                        self.localDatabase.saveIp(myip: data)
                            .disposed(by: self.disposeBag)

                        single(.success(()))
                    }
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

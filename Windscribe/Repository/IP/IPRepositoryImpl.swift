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
    let ipState: BehaviorSubject<IPState?> = BehaviorSubject(value: nil)

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
        load()
    }

    /// Loads the last known IP from the local database
    private func load() {
        localDatabase.getIp()
            .subscribe(onNext: { [weak self] data in
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
    func getIp() -> Single<MyIP> {
        let lastState = try? ipState.value()
        updateState(.updating)
        return apiManager.getIp()
            .flatMap { [weak self] data -> Single<MyIP> in
                guard let self = self else { return Single.just(data) }
                self.localDatabase.saveIp(myip: data)
                    .disposed(by: self.disposeBag)
                return Single.just(data)
            }.do(onError: { [weak self] _ in
                self?.updateState(lastState)
            })
    }

    private func updateState(_ ipState: IPState?) {
        DispatchQueue.main.async {
            self.ipState.onNext(ipState)
        }
    }
}

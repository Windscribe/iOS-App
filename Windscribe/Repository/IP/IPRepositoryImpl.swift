//
//  IPRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class IPRepositoryImpl: IPRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    let currentIp: ReplaySubject<MyIP?> = ReplaySubject.create(bufferSize: 1)

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
        load()
    }

    private func load() {
        localDatabase.getIp().subscribe(onNext: { [self] data in
            currentIp.onNext(data)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func getIp() -> Single<MyIP> {
        logger.logD(self, "Updating ip from repository.")
        return apiManager.getIp().flatMap { [self] data in
            localDatabase.saveIp(myip: data).disposed(by: disposeBag)
            return Single.just(data)
        }
    }
}

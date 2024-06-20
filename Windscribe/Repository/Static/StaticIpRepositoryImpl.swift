//
//  LocationRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
class StaticIpRepositoryImpl: StaticIpRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let disposeBag = DisposeBag()
    private let logger: FileLogger
    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
    }

    func getStaticServers() -> Single<[StaticIP]> {
        return apiManager.getStaticIpList().map {
            self.localDatabase.deleteStaticIps(ignore: $0.staticIPs.toArray().map { $0.staticIP })
            self.localDatabase.saveStaticIPs(staticIps: $0.staticIPs.toArray())
            return $0.staticIPs.toArray()
        }.catch { error in
            if let ips = self.localDatabase.getStaticIPs() {
                return Single.just(ips)
            } else {
                return Single.error(error)
            }
        }
    }

    func getStaticIp(id: Int) -> StaticIP? {
        return localDatabase.getStaticIPs()?.first { $0.id == id}
    }
}

//
//  StaticIpRepositoryImpl.swift
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
        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.failure(Errors.validationFailure))
                    return
                }

                do {
                    let result = try await self.apiManager.getStaticIpList()
                    await MainActor.run {
                        self.localDatabase.deleteStaticIps(ignore: Array(result.staticIPs).map { $0.staticIP })
                        self.localDatabase.saveStaticIPs(staticIps: Array(result.staticIPs))
                        single(.success(Array(result.staticIPs)))
                    }
                } catch {
                    await MainActor.run {
                        self.logger.logE("StaticIpRepository", "Error getting static IPs: \(error)")
                        if let ips = self.localDatabase.getStaticIPs() {
                            single(.success(ips))
                        } else {
                            single(.failure(error))
                        }
                    }
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func getStaticIp(id: Int) -> StaticIP? {
        return localDatabase.getStaticIPs()?.first { $0.id == id }
    }
}

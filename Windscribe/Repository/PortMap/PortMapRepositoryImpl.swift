//
//  PortMapRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class PortMapRepositoryImpl: PortMapRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
    }

    func getUpdatedPortMap() -> Single<[PortMap]> {
        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.failure(Errors.validationFailure))
                    return
                }

                do {
                    let portList = try await self.apiManager.getPortMap(version: APIParameterValues.portMapVersion, forceProtocols: APIParameterValues.forceProtocols)
                    await MainActor.run {
                        self.localDatabase.savePortMap(portMap: Array(portList.portMaps))
                        if let suggested = portList.suggested {
                            self.localDatabase.saveSuggestedPorts(suggestedPorts: [suggested])
                        }
                        single(.success(Array(portList.portMaps)))
                    }
                } catch {
                    await MainActor.run {
                        if let portMaps = self.localDatabase.getPortMap() {
                            single(.success(portMaps))
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
}

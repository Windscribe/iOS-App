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
        return apiManager.getPortMap(version: APIParameterValues.portMapVersion, forceProtocols: APIParameterValues.forceProtocols).map { portList in
            self.localDatabase.savePortMap(portMap: Array(portList.portMaps))
            if let suggested = portList.suggested {
                self.localDatabase.saveSuggestedPorts(suggestedPorts: [suggested])
            }
            return Array(portList.portMaps)
        }.catch { error in
            if let portMaps = self.localDatabase.getPortMap() {
                return Single.just(portMaps)
            } else {
                return Single.error(error)
            }
        }
    }
}

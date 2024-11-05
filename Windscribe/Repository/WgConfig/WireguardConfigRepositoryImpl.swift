//
//  WireguardConfigRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class WireguardConfigRepositoryImpl: WireguardConfigRepository {
    private let apiCallManager: WireguardAPIManager
    private let logger: FileLogger
    private let fileDatabase: FileDatabase
    private let wgCrendentials: WgCredentials
    private let alertManager: AlertManagerV2?
    private let disposeBag = DisposeBag()
    init(apiCallManager: WireguardAPIManager, fileDatabase: FileDatabase, wgCrendentials: WgCredentials, alertManager: AlertManagerV2?, logger: FileLogger) {
        self.apiCallManager = apiCallManager
        self.fileDatabase = fileDatabase
        self.wgCrendentials = wgCrendentials
        self.alertManager = alertManager
        self.logger = logger
    }

    func getCredentials() -> Completable {
        return wgInit().flatMap { _ in
            self.wgConnect()
        }.flatMapCompletable { _ in
            if let error = self.templateWgConfig() {
                self.logger.logE(self, "Templated wg config failed with error \(error)")
                return Completable.error(Errors.parsingError)
            } else {
                return Completable.empty()
            }
        }
    }

    private func wgInit() -> Single<Bool> {
        return Single.just(wgCrendentials.initialized()).flatMap { initlized in
            if initlized {
                return Single.just(true)
            } else {
                let userPublicKey = self.wgCrendentials.getPublicKey() ?? ""
                return self.apiCallManager.wgConfigInit(clientPublicKey: userPublicKey, deleteOldestKey: false)
                    .catch { error in
                        if self.wgCrendentials.deleteOldestKey {
                            return self.apiCallManager.wgConfigInit(clientPublicKey: userPublicKey, deleteOldestKey: true)
                        } else {
                            return Single.error(error)
                        }
                    }.flatMap { config in
                        self.wgCrendentials.saveInitResponse(config: config)
                        return Single.just(true)
                    }
            }
        }
    }

    private func wgConnect() -> Single<Bool> {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let publicKey = wgCrendentials.getPublicKey() ?? ""
        let hostName = wgCrendentials.serverHostName ?? ""
        return apiCallManager.wgConfigConnect(clientPublicKey: publicKey, hostname: hostName, deviceId: deviceID)
            .catch { error in
                if case let Errors.apiError(code) = error, code.errorCode == invalidPublicKey {
                    self.wgCrendentials.delete()
                    return self.wgInit().flatMap { _ in
                        self.apiCallManager.wgConfigConnect(clientPublicKey: self.wgCrendentials.getPublicKey() ?? "", hostname: hostName, deviceId: deviceID)
                    }
                } else if case let Errors.apiError(code) = error, code.errorCode == unableToSelectWgIp {
                    return self.apiCallManager.wgConfigConnect(clientPublicKey: self.wgCrendentials.getPublicKey() ?? "", hostname: hostName, deviceId: deviceID)
                } else {
                    return Single.error(error)
                }
            }.map { config in
                self.wgCrendentials.saveConnectResponse(config: config)
                return true
            }
    }

    private func templateWgConfig() -> RepositoryError? {
        if let wgConfig = wgCrendentials.asWgCredentialsString() {
            if let data = wgConfig.data(using: .utf8) {
                fileDatabase.saveFile(data: data, path: FilePaths.wireGuard)
                return nil
            }
        }
        return RepositoryError.failedToTemplateWgConfig
    }
}

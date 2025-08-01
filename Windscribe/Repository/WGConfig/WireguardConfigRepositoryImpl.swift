//
//  WireguardConfigRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

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
                self.logger.logE("WireguardConfigRepositoryImpl", "Templated wg config failed with error \(error)")
                return Completable.error(Errors.parsingError)
            } else {
                return Completable.empty()
            }
        }
    }

    private func wgInit() -> Single<Bool> {
        return Single.create { single in
            Task {
                do {
                    if self.wgCrendentials.initialized() {
                        single(.success(true))
                        return
                    }

                    let userPublicKey = await self.wgCrendentials.getPublicKey() ?? ""

                    do {
                        let config = try await self.apiCallManager.wgConfigInitAsync(clientPublicKey: userPublicKey, deleteOldestKey: false)
                        self.wgCrendentials.saveInitResponse(config: config)
                        single(.success(true))
                    } catch let error as Errors where error == .wgLimitExceeded {
                        if let alertManager = self.alertManager {
                            let accept = try await alertManager.askUser(message: error.description).asPromise()
                            if accept {
                                let config = try await self.apiCallManager.wgConfigInitAsync(clientPublicKey: userPublicKey, deleteOldestKey: true)
                                self.wgCrendentials.saveInitResponse(config: config)
                                single(.success(true))
                            } else {
                                single(.failure(Errors.handled))
                            }
                        } else {
                            let config = try await self.apiCallManager.wgConfigInitAsync(clientPublicKey: userPublicKey, deleteOldestKey: true)
                            self.wgCrendentials.saveInitResponse(config: config)
                            single(.success(true))
                        }
                    }
                } catch {
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }

    private func wgConnect() -> Single<Bool> {
        return Single.create { single in
            Task {
                do {
                    let deviceID = await UIDevice.current.identifierForVendor?.uuidString ?? ""
                    let publicKey = await self.wgCrendentials.getPublicKey() ?? ""
                    let hostName = self.wgCrendentials.serverHostName ?? ""

                    let config = try await self.apiCallManager.wgConfigConnectAsync(clientPublicKey: publicKey, hostname: hostName, deviceId: deviceID)
                    self.wgCrendentials.saveConnectResponse(config: config)
                    single(.success(true))

                } catch let Errors.apiError(code) where code.errorCode == invalidPublicKey {
                    do {
                        self.wgCrendentials.delete()
                        _ = try await self.wgInit().asPromise()
                        let retryKey = await self.wgCrendentials.getPublicKey() ?? ""
                        let config = try await self.apiCallManager.wgConfigConnectAsync(clientPublicKey: retryKey, hostname: self.wgCrendentials.serverHostName ?? "", deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "")
                        self.wgCrendentials.saveConnectResponse(config: config)
                        single(.success(true))
                    } catch {
                        single(.failure(error))
                    }

                } catch let Errors.apiError(code) where code.errorCode == unableToSelectWgIp {
                    do {
                        let retryKey = await self.wgCrendentials.getPublicKey() ?? ""
                        let config = try await self.apiCallManager.wgConfigConnectAsync(clientPublicKey: retryKey, hostname: self.wgCrendentials.serverHostName ?? "", deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "")
                        self.wgCrendentials.saveConnectResponse(config: config)
                        single(.success(true))
                    } catch {
                        single(.failure(error))
                    }

                } catch {
                    single(.failure(error))
                }
            }
            return Disposables.create()
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

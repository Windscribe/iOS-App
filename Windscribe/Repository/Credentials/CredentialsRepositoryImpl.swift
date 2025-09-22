//
//  CredentialsRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Combine

class CredentialsRepositoryImpl: CredentialsRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let fileDatabase: FileDatabase
    private let vpnManager: VPNManager
    private let wifiManager: WifiManager
    private let logger: FileLogger
    private let preferences: Preferences
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    let connectionMode: BehaviorSubject<String?> = BehaviorSubject(value: nil)
    let selectedProtocol: BehaviorSubject<String?> = BehaviorSubject(value: nil)

    init(apiManager: APIManager, localDatabase: LocalDatabase, fileDatabase: FileDatabase, vpnManager: VPNManager, wifiManager: WifiManager, preferences: Preferences, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.fileDatabase = fileDatabase
        self.vpnManager = vpnManager
        self.wifiManager = wifiManager
        self.logger = logger
        self.preferences = preferences
        loadData()
    }

    private func loadData() {
        preferences.getConnectionMode()
            .receive(on: DispatchQueue.main)
            .sink { [self] data in
                connectionMode.onNext(data)
            }
            .store(in: &cancellables)

        preferences.getSelectedProtocol()
            .receive(on: DispatchQueue.main)
            .sink { [self] data in
                selectedProtocol.onNext(data)
            }
            .store(in: &cancellables)
    }

    func getUpdatedOpenVPNCrendentials() -> Single<OpenVPNServerCredentials?> {
        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.success(nil))
                    return
                }

                do {
                    let credentials = try await self.apiManager.getOpenVPNServerCredentials()
                    await MainActor.run {
                        self.localDatabase.saveOpenVPNServerCredentials(credentials: credentials).disposed(by: self.disposeBag)
                        single(.success(credentials))
                    }
                } catch {
                    await MainActor.run {
                        if let credentials = self.localDatabase.getOpenVPNServerCredentials() {
                            single(.success(credentials))
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

    func getUpdatedIKEv2Crendentials() -> Single<IKEv2ServerCredentials?> {
        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.success(nil))
                    return
                }

                do {
                    let credentials = try await self.apiManager.getIKEv2ServerCredentials()
                    await MainActor.run {
                        self.localDatabase.saveIKEv2ServerCredentials(credentials: credentials).disposed(by: self.disposeBag)
                        single(.success(credentials))
                    }
                } catch {
                    await MainActor.run {
                        if let credentials = self.localDatabase.getIKEv2ServerCredentials() {
                            single(.success(credentials))
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

    func getUpdatedServerConfig() -> Single<String> {
        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.failure(Errors.validationFailure))
                    return
                }

                do {
                    let config = try await self.apiManager.getOpenVPNServerConfig(openVPNVersion: APIParameterValues.openVPNVersion)
                    if let data = Data(base64Encoded: config) {
                        self.fileDatabase.removeFile(path: FilePaths.openVPN)
                        self.fileDatabase.saveFile(data: data, path: FilePaths.openVPN)
                    }
                    single(.success(config))
                } catch {
                    if let fileContent = self.fileDatabase.readFile(path: FilePaths.openVPN), let serverConfig = String(data: fileContent, encoding: .utf8) {
                        single(.success(serverConfig))
                    } else {
                        single(.failure(error))
                    }
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func selectedServerCredentialsType() -> ServerCredentials.Type {
        guard let result = wifiManager.getConnectedNetwork() else {
            return OpenVPNServerCredentials.self
        }
        if result.preferredProtocolStatus == true && !vpnManager.isFromProtocolFailover && !vpnManager.isFromProtocolChange {
            if result.preferredProtocol == TextsAsset.iKEv2 {
                return IKEv2ServerCredentials.self
            }
            return OpenVPNServerCredentials.self
        } else {
            if let connection = try? connectionMode.value(), let selectedprotocol = try? selectedProtocol.value() {
                if connection == Fields.Values.manual {
                    if selectedprotocol == TextsAsset.iKEv2 {
                        return IKEv2ServerCredentials.self
                    }
                    return OpenVPNServerCredentials.self
                } else {
                    if result.protocolType == TextsAsset.iKEv2 {
                        return IKEv2ServerCredentials.self
                    }
                    return OpenVPNServerCredentials.self
                }
            }
        }
        return OpenVPNServerCredentials.self
    }

    func updateServerConfig() {
        if preferences.getSessionAuthHash() == nil {
            return
        }

        getUpdatedOpenVPNCrendentials().flatMap { _ in
            return self.getUpdatedServerConfig()
        }.subscribe(onSuccess: { _ in
            self.logger.logI("CredentialsRepositoryImpl", "Server config updated.")
        }, onFailure: { _ in
            self.logger.logE("CredentialsRepositoryImpl", "Failed to update server config.")
        }).disposed(by: disposeBag)
    }
}

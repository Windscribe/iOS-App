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

class CredentialsRepositoryImpl: CredentialsRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let fileDatabase: FileDatabase
    private let vpnManager: VPNManager
    private let wifiManager: WifiManager
    private let logger: FileLogger
    private let preferences: Preferences
    private let disposeBag = DisposeBag()
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
        preferences.getConnectionMode().subscribe(onNext: { [self] data in
            connectionMode.onNext(data)
        }, onError: { _ in }).disposed(by: disposeBag)
        preferences.getSelectedProtocol().subscribe(onNext: { [self] data in
            selectedProtocol.onNext(data)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func getUpdatedOpenVPNCrendentials() -> Single<OpenVPNServerCredentials?> {
        return apiManager.getOpenVPNServerCredentials().map { credentials in
            self.localDatabase.saveOpenVPNServerCredentials(credentials: credentials).disposed(by: self.disposeBag)
            return credentials
        }.catch { error in
            if let credentials = self.localDatabase.getOpenVPNServerCredentials() {
                return Single.just(credentials)
            } else {
                return Single.error(error)
            }
        }
    }

    func getUpdatedIKEv2Crendentials() -> Single<IKEv2ServerCredentials?> {
        return apiManager.getIKEv2ServerCredentials().map { credentials in
            self.localDatabase.saveIKEv2ServerCredentials(credentials: credentials).disposed(by: self.disposeBag)
            return credentials
        }.catch { error in
            if let credentials = self.localDatabase.getIKEv2ServerCredentials() {
                return Single.just(credentials)
            } else {
                return Single.error(error)
            }
        }
    }

    func getUpdatedServerConfig() -> Single<String> {
        return apiManager.getOpenVPNServerConfig(openVPNVersion: APIParameterValues.openVPNVersion).map { config in
            if let data = Data(base64Encoded: config) {
                self.fileDatabase.removeFile(path: FilePaths.openVPN)
                self.fileDatabase.saveFile(data: data, path: FilePaths.openVPN)
            }
            return config
        }.catch { error in
            if let fileContent = self.fileDatabase.readFile(path: FilePaths.openVPN), let serverConfig = String(data: fileContent, encoding: .utf8) {
                return Single.just(serverConfig)
            } else {
                return Single.error(error)
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
            if let connection = try? connectionMode.value(),
               let selectedprotocol = try? selectedProtocol.value()
            {
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
        logger.logD(self, "Updating open vpn credentials.")
        getUpdatedOpenVPNCrendentials().flatMap { _ in
            self.logger.logD(self, "Updating open vpn server config.")
            return self.getUpdatedServerConfig()
        }.subscribe(onSuccess: { _ in
            self.logger.logD(self, "Server config updated.")
        }, onFailure: { _ in self.logger.logD(self, "Failed to update server config.") }).disposed(by: disposeBag)
    }
}

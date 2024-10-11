//
//  IntentVPNManager.swift
//  SiriIntents
//
//  Created by Andre Fonseca on 30/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import WidgetKit
import NetworkExtension

class IntentVPNManager {
    var logger: FileLogger
    var kcDb: KeyChainDatabase
    var api: WSNetServerAPI
    var hasDoneSetup = false
    var checkConnectionCompletion: ((Bool) -> Void)?
    lazy var openVPNManager: IntentVPNManagerType = {
        GenericVPNManager(userName: .openVPN, logger: logger, kcDb: kcDb)
    }()
    lazy var wireguardVPNManager: IntentVPNManagerType = {
        GenericVPNManager(userName: .wireGuard, logger: logger, kcDb: kcDb)
    }()
    lazy var ikev2VPNManager: IntentVPNManagerType = {
        IKEv2IntentVPNManager(logger: logger, kcDb: kcDb)
    }()

    init(logger: FileLogger, kcDb: KeyChainDatabase, api: WSNetServerAPI) {
        self.logger = logger
        self.kcDb = kcDb
        self.api = api
    }

    var isActive: Bool {
        return openVPNManager.isConfigured() || wireguardVPNManager.isConfigured() || ikev2VPNManager.isConfigured()
    }

    func isConnected() -> Bool {
        return (ikev2VPNManager.isConnected() && ikev2VPNManager.isConfigured()) ||
        (openVPNManager.isConnected() && openVPNManager.isConfigured()) ||
        (wireguardVPNManager.isConnected() && wireguardVPNManager.isConfigured())
    }

    func setup (completion: @escaping() -> Void) {
        guard !hasDoneSetup else {
            completion()
            return
        }
        hasDoneSetup.toggle()
        ikev2VPNManager.setup {
            self.openVPNManager.setup {
                self.wireguardVPNManager.setup {
                    completion()
                }
            }
        }
//        if #available(iOSApplicationExtension 15.0, iOS 15.0, *) {
//            Task {
//                await self.awaitConnectionChange()
//            }
//        }
    }

    func checkConnection(completion: @escaping(Bool) -> Void) {
        checkConnectionCompletion = completion
        if (ikev2VPNManager.isConnected() && ikev2VPNManager.isConfigured())  {
            completion(true)
            return
        }
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if error == nil {
                completion(managers?.first?.connection.status == .connected)
                return
            }
            completion(false)
        }
    }

    func disconnect(completion: @escaping(_ result: Bool) -> Void) {
        [ikev2VPNManager, openVPNManager, wireguardVPNManager].forEach {
            if $0.isConnected() {
                $0.disconnect() { completion($0) }
                return
            }
        }
    }

    func connect(completion: @escaping(_ result: Bool) -> Void) {
        [(openVPNManager, [ikev2VPNManager, wireguardVPNManager]),
         (wireguardVPNManager, [ikev2VPNManager, openVPNManager]),
         (ikev2VPNManager, [openVPNManager, wireguardVPNManager])].forEach {
            if $0.isDisconnected() && $0.isConfigured() {
                $0.connect(otherProviders: $1) {
                    completion($0)
                }
                return
            }
        }
    }

    func getIPAddress(completion: @escaping (_ ipAddress: String?, _ error: String?) -> Void) {
        api.myIP { code, myIp in
            if code == 0, let data = myIp.data(using: .utf8),
               let ipObject: IntentMyIP = try? JSONDecoder().decode(IntentMyIP.self, from: data) {
                completion(ipObject.userIp, nil)
            } else {
                completion(nil, "Unable to get IP Address.")
            }
        }
    }
}

extension IntentVPNManager {
    @available(iOSApplicationExtension 13.0.0, iOS 13.0, *)
    func getIPAddress() async -> String? {
        await withCheckedContinuation { continuation in
            getIPAddress { (ipAddress, error) in
                continuation.resume(returning: ipAddress)
            }
        }
    }

    @available(iOSApplicationExtension 13.0.0, iOS 13.0, *)
    func setup() async {
        await withCheckedContinuation { continuation in
            setup { continuation.resume() }
        }
    }

    @available(iOSApplicationExtension 13.0.0, iOS 13.0, *)
    func connect() async -> Bool? {
        await withCheckedContinuation { continuation in
            connect { continuation.resume(returning: $0) }
        }
    }

    @available(iOSApplicationExtension 13.0.0, iOS 13.0, *)
    func disconnect() async -> Bool? {
        await withCheckedContinuation { continuation in
            disconnect { continuation.resume(returning: $0) }
        }
    }
}

private struct IntentMyIP: Decodable {
    dynamic var userIp: String = ""
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case userIp = "user_ip"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        userIp = try data.decode(String.self, forKey: .userIp)
    }
}

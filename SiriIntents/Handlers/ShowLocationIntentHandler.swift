//
//  ShowLocationIntentHandler.swift
//  SiriIntents
//
//  Created by Andre Fonseca on 25/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Swinject

class ShowLocationIntentHandler: NSObject, ShowLocationIntentHandling {
    // MARK: Dependencies
    private lazy var container: Container = {
        self.container = Container(isIntentExt: true)
        container.injectCore()
        return container
    }()
    private lazy var logger: FileLogger = {
        return container.resolve(FileLogger.self)!
    }()
    private lazy var preferences: Preferences = {
        return container.resolve(Preferences.self)!
    }()
    private lazy var vpnManager: IntentVPNManager = {
        return container.resolve(IntentVPNManager.self)!
    }()

    func getPreferences() -> Preferences {
      return container.resolve(Preferences.self) ?? SharedSecretDefaults()
    }

    func confirm(intent: ShowLocationIntent, completion: @escaping (ShowLocationIntentResponse) -> Void) {
        self.getIPAddress { (ipAddress, error) in
            guard ipAddress != nil else {
                completion(ShowLocationIntentResponse(code: .failure, userActivity: nil))
                return
            }
            self.vpnManager.setup {
                completion(ShowLocationIntentResponse(code: .ready, userActivity: nil))
            }
        }
    }

    func handle(intent: ShowLocationIntent, completion: @escaping (ShowLocationIntentResponse) -> Void) {
        self.getIPAddress { (ipAddress, error) in
            guard let ipAddress = ipAddress else {
                completion(ShowLocationIntentResponse(code: .failure, userActivity: nil))
                return
            }
            self.vpnManager.setup {
                if self.vpnManager.isConnected() {
                    let prefs = self.getPreferences()
                    if let serverName = prefs.getServerNameKey(),
                       let nickName = prefs.getNickNameKey() {
                        completion(ShowLocationIntentResponse.success(cityName: serverName, nickName: nickName, ipAddress: ipAddress))
                    }
                } else {
                    completion(ShowLocationIntentResponse.successWithNoConnection(ipAddress: ipAddress))
                }
            }
        }
    }

    func getIPAddress(completion: @escaping (_ ipAddress: String?, _ error: String?) -> Void) {
        vpnManager.getIPAddress { ipAddress, error in
            completion(ipAddress, error)
        }
    }
}

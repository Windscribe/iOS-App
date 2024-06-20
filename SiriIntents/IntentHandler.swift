//
//  IntentHandler.swift
//  SiriIntents
//
//  Created by Yalcin on 2019-07-16.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Intents
import NetworkExtension
import Swinject

class IntentHandler: INExtension {

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        switch intent {
        case is ShowLocationIntent:
            return ShowLocationIntentHandler()
        default:
            return self
        }
    }

}


class ShowLocationIntentHandler: NSObject, ShowLocationIntentHandling {
    // MARK: Dependencies
    private lazy var container: Container = {
        let container = Container()
        container.injectCore()
        return container
    }()
    private lazy var logger: FileLogger = {
        return container.resolve(FileLogger.self)!
    }()
    private lazy var preferences: Preferences = {
        return container.resolve(Preferences.self)!
    }()

    func confirm(intent: ShowLocationIntent, completion: @escaping (ShowLocationIntentResponse) -> Void) {
        self.getIPAddress { (ipAddress, error) in
            guard ipAddress != nil else {
                completion(ShowLocationIntentResponse(code: .failure, userActivity: nil))
                return
            }
            NEVPNManager.shared().loadFromPreferences { error in
                completion(ShowLocationIntentResponse(code: .ready, userActivity: nil))
            }
        }
    }

    func handle(intent: ShowLocationIntent, completion: @escaping (ShowLocationIntentResponse) -> Void) {
        self.getIPAddress { (ipAddress, error) in
            guard let ipAddress = ipAddress else {
                return
            }
            NEVPNManager.shared().loadFromPreferences { error in
                if NEVPNManager.shared().connection.status != .connected {
                    completion(ShowLocationIntentResponse.successWithNoConnection(ipAddress: ipAddress))
                } else {
                    if let serverName = self.preferences.getServerNameKey(),
                       let nickName = self.preferences.getNickNameKey() {
                        completion(ShowLocationIntentResponse.success(cityName: serverName, nickName: nickName, ipAddress: ipAddress))
                    }
                }
            }
        }

    }

    func getIPAddress(completion: @escaping (_ ipAddress: String?, _ error: String?) -> Void) {
        WSNet.instance().serverAPI().myIP { code, myIp in
            if code == 0 {
                completion(myIp, nil)
            } else {
                completion(nil, "Unable to get IP Address.")
            }
        }
    }

}

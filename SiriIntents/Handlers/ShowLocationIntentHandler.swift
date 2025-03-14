//
//  ShowLocationIntentHandler.swift
//  SiriIntents
//
//  Created by Andre Fonseca on 25/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RxSwift
import Swinject

class ShowLocationIntentHandler: NSObject, ShowLocationIntentHandling {
    private let resolver = ContainerResolver()

    private lazy var logger: FileLogger = resolver.getLogger()

    private lazy var preferences: Preferences = resolver.getPreferences()

    private lazy var api: WSNetServerAPI = resolver.getApi()

    private let dispose = DisposeBag()

    func handle(intent _: ShowLocationIntent, completion: @escaping (ShowLocationIntentResponse) -> Void) {
        getIPAddress().subscribe(onSuccess: { ip in
            let protocolType = self.preferences.getActiveManagerKey() ?? "WireGuard"
            getActiveManager(for: protocolType) { result in
                switch result {
                case let .success(manager):
                    guard let serverName = self.preferences.getServerNameKey(),
                          let nickName = self.preferences.getNickNameKey()
                    else {
                        completion(ShowLocationIntentResponse(code: .failure, userActivity: nil))
                        return
                    }
                    if manager.connection.status == .connected {
                        completion(ShowLocationIntentResponse.success(cityName: serverName, nickName: nickName, ipAddress: ip.userIp))
                    } else {
                        completion(ShowLocationIntentResponse.successWithNoConnection(ipAddress: ip.userIp))
                    }
                case .failure:
                    completion(ShowLocationIntentResponse.successWithNoConnection(ipAddress: ip.userIp))
                }
            }

        }, onFailure: { _ in
            completion(ShowLocationIntentResponse(code: .failure, userActivity: nil))
        }).disposed(by: dispose)
    }

    fileprivate func getIPAddress() -> Single<IntentMyIP> {
        return makeApiCall(modalType: IntentMyIP.self) { completion in
            self.api.myIP(completion)
        }
    }
}

private struct IntentMyIP: Decodable {
    dynamic var userIp: String = ""
    enum CodingKeys: String, CodingKey {
        case data
        case userIp = "user_ip"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        userIp = try data.decode(String.self, forKey: .userIp)
    }
}

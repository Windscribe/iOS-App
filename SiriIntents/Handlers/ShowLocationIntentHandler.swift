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
    private let resolver = ContainerResolver()

    private lazy var logger: FileLogger = resolver.getLogger()

    private lazy var preferences: Preferences = resolver.getPreferences()

    private lazy var api: WSNetServerAPI = resolver.getApi()

    private lazy var apiUtil: APIUtilService = resolver.getApiUtil()

    func handle(intent _: ShowLocationIntent, completion: @escaping (ShowLocationIntentResponse) -> Void) {
        Task {
            do {
                let ip = try await apiUtil.makeApiCall(modalType: IntentMyIP.self) { completion in
                    self.api.myIP(completion)
                }

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
            } catch {
                completion(ShowLocationIntentResponse(code: .failure, userActivity: nil))
            }
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

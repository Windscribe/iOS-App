//
//  ShowLocation.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-15.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import AppIntents
import Foundation
import NetworkExtension
@preconcurrency import Swinject

@available(iOS 16.0, *)
@available(iOSApplicationExtension, unavailable)
extension ShowLocation: ForegroundContinuableIntent {}
@available(iOS 16.0, *)
struct ShowLocation: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "ShowLocationIntent"

    static var title: LocalizedStringResource = LocalizedStringResource("ShowLocation.intentTitle", table: "SiriIntents")
    static var description = IntentDescription(LocalizedStringResource("ShowLocation.intentDescription", table: "SiriIntents"))

    static var parameterSummary: some ParameterSummary {
        Summary("Connection State")
    }
    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction {
            DisplayRepresentation(
                title: LocalizedStringResource("ShowLocation.intentTitle"),
                subtitle: LocalizedStringResource("ShowLocation.intentDescription")
            )
        }
    }

    private var resolver: ContainerResolver {
        ContainerResolver()
    }

    private var apiUtil: APIUtilService {
        return resolver.getApiUtil()
    }

    var preferences: Preferences {
        return resolver.getPreferences()
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let ip = try await getMyIp()
            do {
                let protocolType = preferences.getActiveManagerKey() ?? "WireGuard"
                let activeManager = try await getNEVPNManager(for: protocolType)
                if activeManager.connection.status == NEVPNStatus.connected {
                    let prefs = resolver.getPreferences()
                    if let serverName = prefs.getServerNameKey(), let nickName = prefs.getNickNameKey() {
                        return .result(dialog: .responseSuccess(cityName: serverName, nickName: nickName, ipAddress: ip))
                    } else {
                        return .result(dialog: .responseSuccessWithNoConnection(ipAddress: ip))
                    }
                } else {
                    return .result(dialog: .responseSuccessWithNoConnection(ipAddress: ip))
                }
            } catch {
                return .result(dialog: .responseSuccessWithNoConnection(ipAddress: ip))
            }
        } catch {
            return .result(dialog: .responseFailureState)
        }
    }

    func getMyIp() async throws -> String {
        let result = try await apiUtil.makeApiCall(modalType: IntentMyIP.self) { completion in
            self.resolver.getApi().myIP(completion)
        }
        return result.userIp
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

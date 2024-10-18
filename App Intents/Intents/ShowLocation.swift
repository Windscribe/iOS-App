//
//  ShowLocation.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-15.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import AppIntents
import RxSwift
import NetworkExtension
@preconcurrency import Swinject

@available(iOS 16.0, *)
@available(iOSApplicationExtension, unavailable)
extension ShowLocation: ForegroundContinuableIntent { }
@available(iOS 16.0, *)
struct ShowLocation: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "ShowLocationIntent"

    static var title: LocalizedStringResource = "Connection State"
    static var description = IntentDescription("View connected location and IP address.")

    static var parameterSummary: some ParameterSummary {
        Summary("Connection State")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction {
            DisplayRepresentation(
                title: "Connection State",
                subtitle: "View connected location and IP address"
            )
        }
    }

    fileprivate let resolver = ContainerResolver()

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
           let ip = try await getMyIp()
            do {
                let manager = try await getActiveManager()
                if manager.connection.status == NEVPNStatus.connected {
                    let prefs = resolver.getPreferences()
                    if let serverName = prefs.getServerNameKey(),
                       let nickName = prefs.getNickNameKey() {
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

    fileprivate func getIPAddress() -> Single<IntentMyIP> {
        return makeApiCall(modalType: IntentMyIP.self) { completion in
            self.resolver.getApi().myIP(completion)
        }
    }

    func getMyIp() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            _ = getIPAddress()
                .subscribe(onSuccess: { result in
                    continuation.resume(returning: result.userIp)
                }, onFailure: { error in
                    continuation.resume(throwing: error)
                })
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

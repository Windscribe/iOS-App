//
//  ShowLocation.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import AppIntents
@preconcurrency import Swinject

@available(iOS 16.0, *)
struct ShowLocation: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "ShowLocationIntent"

    static var title: LocalizedStringResource = "Connection State"
    static var description = IntentDescription("View connected location and ip address.")

    static var parameterSummary: some ParameterSummary {
        Summary("Connection State")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction {
            DisplayRepresentation(
                title: "Connection State",
                subtitle: "View connected location and ip address"
            )
        }
    }

    let resolver = ContainerResolver()

    func perform() async throws -> some IntentResult & ProvidesDialog {
        if let vpnManager = resolver.getVpnManager(), let ipAddress = await vpnManager.getIPAddress() {
            await vpnManager.setup()
            if vpnManager.isConnected() {
                let prefs = resolver.getPreferences()
                if let serverName = prefs.getServerNameKey(),
                   let nickName = prefs.getNickNameKey() {
                    return .result(dialog: .responseSuccess(cityName: serverName, nickName: nickName, ipAddress: ipAddress))
                }
            } else {
                return .result(dialog: .responseSuccessWithNoConnection(ipAddress: ipAddress))
            }
        }
        return .result(dialog: .responseFailure)
    }
}

@available(iOS 16.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static func responseSuccess(cityName: String, nickName: String, ipAddress: String) -> Self {
        "You are connected to \(cityName), \(nickName) and your IP address is \(ipAddress)."
    }
    static var responseFailure: Self {
        "Sorry, but I couldn't the find the information you are looking for."
    }
    static func responseSuccessWithNoConnection(ipAddress: String) -> Self {
        "You are not connected to VPN. Your  IP address is \(ipAddress)."
    }
}

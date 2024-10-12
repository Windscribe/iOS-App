//
//  Connect.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import AppIntents
import WidgetKit
import NetworkExtension
enum AppIntentError: Error {
    case VPNNotConfigured
}
@available(iOS 16.0, *)
@available(iOSApplicationExtension, unavailable)
extension Connect: ForegroundContinuableIntent { }
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct Connect: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Enable Windscribe VPN"
    static var description = IntentDescription("Connects Windscribe VPN")
    let tag = "AppIntents"
    static var parameterSummary: some ParameterSummary {
        Summary("Connect to VPN")
    }

    fileprivate let logger = ContainerResolver().getLogger()
    func perform() async throws -> some IntentResult & ProvidesDialog {
        logger.logD(tag, "Enable VPN action called.")
        do {
            let activeManager = try await getActiveManager()
            let vpnStatus = activeManager.connection.status
            // Already connected just update status.
            if vpnStatus == NEVPNStatus.connected {
                return .result(dialog: .responseSuccess)
            }
            activeManager.isEnabled = true
            activeManager.isOnDemandEnabled = true
            try await activeManager.saveToPreferences()
            try activeManager.connection.startVPNTunnel()
            var iterations = 0
            while iterations <= 10 {
                try? await Task.sleep(for: .milliseconds(500))
                if activeManager.connection.status == .connected {
                    WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
                    logger.logD(tag, "Connected to VPN.")
                    return .result(dialog: .responseSuccess)
                }
                iterations += 1
                logger.logD(tag, "Awaiting connection to VPN.")
            }
            logger.logD(tag, "Taking too long to connect.")
            WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
            return .result(dialog: .responseFailure)
        } catch let error {
            logger.logD(tag, "Error connecting to VPN: \(error)")
            WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
            return .result(dialog: .responseFailure)
        }
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static var responseSuccess: Self {
        "Connection request to the VPN was successful."
    }
    static var responseFailure: Self {
        "Sorry, something went wrong while trying to connect, please check the Windscribe app."
    }
}

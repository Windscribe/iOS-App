//
//  Connect.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import AppIntents
import Foundation
import NetworkExtension
import WidgetKit

@available(iOS 16.0, *)
@available(iOSApplicationExtension, unavailable)
extension Connect: ForegroundContinuableIntent {}
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct Connect: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("Connect.intentTitle", table: "SiriIntents")
    static var description = IntentDescription(LocalizedStringResource("Connect.intentDescription", table: "SiriIntents"))

    let tag = "AppIntents"
    static var parameterSummary: some ParameterSummary {
        Summary("Connect to VPN")
    }

    fileprivate let resolver = ContainerResolver()

    var logger: FileLogger {
        return resolver.getLogger()
    }

    var preferences: Preferences {
        return resolver.getPreferences()
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        logger.logI(tag, "Enable VPN action called.")
        do {
            let protocolType = preferences.getActiveManagerKey() ?? "WireGuard"
            let activeManager = try await getNEVPNManager(for: protocolType)
            let vpnStatus = activeManager.connection.status
            // If it's invalid it will not connect
            guard vpnStatus != .invalid else {
                logger.logI(tag, "Invalid VPN Manager.")
                WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
                return .result(dialog: .responseFailure)
            }
            // Already connected just update status.
            if vpnStatus == .connected {
                WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
                return .result(dialog: .responseSuccess)
            }
            // If already connecting then just wait for it to finish
            if vpnStatus != .connecting {
                activeManager.isEnabled = true
                activeManager.isOnDemandEnabled = true
                try await activeManager.saveToPreferences()
                try activeManager.connection.startVPNTunnel()
            }
            var iterations = 0
            while iterations <= 20 {
                try? await Task.sleep(for: .milliseconds(500))
                if activeManager.connection.status == .connected {
                    WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
                    logger.logI(tag, "Connected to VPN.")
                    return .result(dialog: .responseSuccess)
                }
                iterations += 1
                logger.logI(tag, "Awaiting connection to VPN.")
            }
            logger.logI(tag, "Taking too long to connect.")
            WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
            return .result(dialog: .responseTimeoutFailure)
        } catch {
            logger.logE("Connect", "Error connecting to VPN: \(error.localizedDescription)")
            WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
            return .result(dialog: .responseFailure)
        }
    }
}

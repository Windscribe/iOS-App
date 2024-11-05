//
//  Disconnect.swift
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
extension Disconnect: ForegroundContinuableIntent {}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct Disconnect: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Disable Windscribe VPN"
    static var description = IntentDescription("Disconnects Windscribe from VPN.")
    let tag = "AppIntents"
    fileprivate let logger = ContainerResolver().getLogger()
    func perform() async throws -> some IntentResult & ProvidesDialog {
        logger.logD(tag, "Disable VPN action called.")
        do {
            let activeManager = try await getActiveManager()
            let vpnStatus = activeManager.connection.status
            // Already disconnected just update status.
            if [NEVPNStatus.disconnected, NEVPNStatus.disconnecting, NEVPNStatus.invalid].contains(vpnStatus) {
                return .result(dialog: .responseSuccessDisconnect)
            }
            activeManager.isEnabled = true
            activeManager.isOnDemandEnabled = false
            try await activeManager.saveToPreferences()
            activeManager.connection.stopVPNTunnel()

            var iterations = 0
            while iterations <= 10 {
                try? await Task.sleep(for: .milliseconds(500))
                if activeManager.connection.status == .disconnected {
                    WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
                    logger.logD(tag, "Disconnected from VPN.")
                    return .result(dialog: .responseSuccessDisconnect)
                }
                iterations += 1
                logger.logD(tag, "Awaiting disconnect from VPN.")
            }
            WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
            logger.logD(tag, "Taking too long to disconnect.")
            return .result(dialog: .responseFailureDisconnect)
        } catch {
            logger.logD(tag, "Error disconnecting from VPN: \(error)")
            WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
            return .result(dialog: .responseFailureDisconnect)
        }
    }
}

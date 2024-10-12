//
//  Disconnect.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import AppIntents
import WidgetKit
import NetworkExtension

@available(iOS 16.0, *)
@available(iOSApplicationExtension, unavailable)
extension Disconnect: ForegroundContinuableIntent { }

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
                return .result(dialog: .responseSuccess)
            }
            activeManager.isEnabled = true
            activeManager.isOnDemandEnabled = false
            try await activeManager.saveToPreferences()
            activeManager.connection.stopVPNTunnel()
            WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
            logger.logD(tag, "Disconnected from VPN")
            return .result(dialog: .responseSuccess)
        } catch let error {
            logger.logD(tag, "Error disconnecting from VPN: \(error)")
            WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
            return .result(dialog: .responseFailure)
        }
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static var responseSuccess: Self {
        "Disconnect request of the VPN was successful."
    }
    static var responseFailure: Self {
        "Sorry, something went wrong while trying to disconnect, please check the Windscribe app."
    }
}

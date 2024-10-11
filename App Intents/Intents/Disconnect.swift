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

@available(iOS 16.0, *)
@available(iOSApplicationExtension, unavailable)
extension Disconnect: ForegroundContinuableIntent { }

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct Disconnect: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Disable Windscribe VPN"
    static var description = IntentDescription("Disconnects Windscribe from VPN.")

    let resolver = ContainerResolver()

    func perform() async throws -> some IntentResult & ProvidesDialog {
        resolver.getPreferences().saveConnectionRequested(value: false)
        resolver.getLogger().logD(self, "Disable VPN action called.")
        if let vpnManager = resolver.getVpnManager() {
            await vpnManager.setup()
            if await vpnManager.disconnect() ?? false {
                resolver.getLogger().logD(self, "Reloading timeline.")
                WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
                return .result(dialog: .responseSuccess)
            }
        }
        resolver.getLogger().logD(self, "Issue disabling the VPN")
        WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
        return .result(dialog: .responseFailure)
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

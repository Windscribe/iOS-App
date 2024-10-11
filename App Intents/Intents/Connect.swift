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

@available(iOS 16.0, *)
@available(iOSApplicationExtension, unavailable)
extension Connect: ForegroundContinuableIntent { }

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct Connect: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Enable Windscribe VPN"
    static var description = IntentDescription("Connects Windscribe VPN")

    static var parameterSummary: some ParameterSummary {
        Summary("Connect to VPN")
    }

    let resolver = ContainerResolver()

    func perform() async throws -> some IntentResult & ProvidesDialog {
        resolver.getLogger().logD(self, "Enable VPN action called.")
        resolver.getPreferences().saveConnectionRequested(value: true)
        if let vpnManager = resolver.getVpnManager() {
            await vpnManager.setup()
            if await vpnManager.connect() ?? false {
                resolver.getLogger().logD(self, "Reloading timeline.")
                WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
                return .result(dialog: .responseSuccess)
            }
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
        return .result(dialog: .responseFailure)
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

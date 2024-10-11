//
//  ShortcutProvider.swift
//  Windscribe
//
//  Created by Andre Fonseca on 01/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import AppIntents

@available(iOSApplicationExtension 17.0, iOS 16.0, *)
struct ShortcutsProvider: AppShortcutsProvider {
  @AppShortcutsBuilder
  static var appShortcuts: [AppShortcut] {
      AppShortcut(intent: ShowLocation(),
                   phrases: ["Show connected location in \(.applicationName)",
                             "Show connection status in \(.applicationName)",
                             "Show \(.applicationName) connection status",
                             "Show \(.applicationName) location"],
                   shortTitle: "Show connected location",
                   systemImageName: "network")
      AppShortcut(intent: Connect(),
                  phrases: ["Connect with \(.applicationName)",
                            "Connect \(.applicationName) to VPN",
                            "Connect to \(.applicationName)",
                            "Connect to \(.applicationName) VPN"],
                  shortTitle: "Connected to VPN",
                  systemImageName: "bolt.horizontal.circle.fill")
      AppShortcut(intent: Disconnect(),
                  phrases: ["Disconnect from \(.applicationName)",
                            "Disconnect VPN in \(.applicationName)",
                            "Disconnect from \(.applicationName) VPN"],
                  shortTitle: "Disconnect from VPN",
                  systemImageName: "bolt.horizontal.circle")

  }
}

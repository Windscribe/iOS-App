//
//  HelpSettingsItem.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-28.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

enum HelpLogStatus {
    case idle
    case sending
    case success
    case failure(String)
}

enum HelpMenuEntryType: Hashable {
    case link(icon: String, title: String, subtitle: String?, urlString: String)
    case navigation(icon: String, title: String, subtitle: String?, route: HelpRoute)
    case sendDebugLog(icon: String, title: String)
    case communitySupport(redditURLString: String, discordURLString: String)
}

enum HelpRoute: Hashable {
    case submitTicket
    case advanceParams
    case viewLog
}

struct HelpAlert: Identifiable {
    var id = UUID()
    let title: String
    let message: String
    let buttonText: String
}

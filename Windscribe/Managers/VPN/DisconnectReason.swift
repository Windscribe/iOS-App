//
//  DisconnectReason.swift
//  Windscribe
//
//  Created by Ginder Singh on 2026-02-11.
//  Copyright © 2026 Windscribe. All rights reserved.
//

enum DisconnectReason: Int {
    case accountStatusChanged = 1  // Account changed from okay to > Banned/Expired
    case userStatusChanged = 2     // User status changed from premium to free or vice versa.
    case invalidSession = 3        // Invalid session.
    case unknown = 0               // Catch-all
}

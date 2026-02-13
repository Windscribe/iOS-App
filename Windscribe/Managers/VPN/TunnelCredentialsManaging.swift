//
//  TunnelCredentialsManaging.swift
//  Windscribe
//
//  Created by Ginder Singh on 2026-02-11.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Protocol for tunnel providers to manage their credentials
/// Methods must be called on the main thread as they interact with NetworkExtension APIs
public protocol TunnelCredentialsManaging: AnyObject {
    @MainActor func deleteCredentials(error: NSError)
}

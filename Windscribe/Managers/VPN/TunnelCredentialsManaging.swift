//
//  TunnelCredentialsManaging.swift
//  Windscribe
//
//  Created by Ginder Singh on 2026-02-11.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Protocol for tunnel providers to manage their credentials
public protocol TunnelCredentialsManaging: AnyObject {
    func deleteCredentials(error: NSError)
}

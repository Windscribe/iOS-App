//
//  WSNetPingManagerType.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-07.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Swift-side surface of `WSNetPingManager`. The concrete class satisfies
/// this via empty extension; tests substitute their own mocks.
protocol WSNetPingManagerType {
    func ping(_ ip: String,
              hostname: String,
              pingType: Int32,
              callback: @escaping (String, Bool, Int32, Bool) -> Void) -> WSNetCancelableCallback
}

extension WSNetPingManager: WSNetPingManagerType {}

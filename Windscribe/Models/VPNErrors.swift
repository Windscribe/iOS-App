//
//  VPNErrors.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-09-22.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum VPNErrors: Error, CustomStringConvertible {
    case credentialsFailure
    var description: String {
        switch self {
        case .credentialsFailure:
            return "Credentials failure."
        }
    }
}

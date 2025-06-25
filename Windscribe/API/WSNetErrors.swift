//
//  WSNetErrors.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

enum WSNetErrors: Int32 {
    case success = 0
    case networkError = 1
    case noNetworkConnection = 2
    case incorrectJson = 3
    case failOverFailed = 4

    var error: Error? {
        switch self {
        case .success:
            return nil
        case .networkError:
            return Errors.unknownError
        case .noNetworkConnection:
            return Errors.noNetwork
        case .incorrectJson:
            return Errors.parsingError
        case .failOverFailed:
            return Errors.tooManyFailedAttempts
        }
    }
}

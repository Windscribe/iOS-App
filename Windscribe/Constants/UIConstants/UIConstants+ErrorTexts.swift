//
//  UIConstants+ErrorTexts.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-06-24.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

enum ErrorTexts {
    enum APIError {
        case validationFailure
        case invalidSession
        case unableToUpgradeUser
        case unableToVerifyWithApple
        case sandboxReceipt
        case missingTransactionId
        case duplicateTransactionId
        case noNetwork
        case unknownError
        case datanotfound
        case ipNotAvailable
        case missingRemoteAddress
        case wgLimitExceeded
        case twoFactorRequired
        case tooManyFailedAttempts
        case invalid2FA
        case unspecifiedError

        var description: String {
            unlocalizedDescription.localized
        }

        var unlocalizedDescription: String {
            switch self {
                case .validationFailure:
                return "Invalid session auth or api parameters provided."
            case .invalidSession:
                return "Invalid session auth."
            case .unableToUpgradeUser:
                return "Failed to process the upgrade using the receipt."
            case .unableToVerifyWithApple:
                return "Unable to verify the receipt with Apple."
            case .sandboxReceipt:
                return "Windscribe does not support upgrades through the TestFlight version. If you've made a payment during the TestFlight period, rest assured that it won't be charged, as it is solely for testing purposes."
            case .missingTransactionId:
                return "Missing transaction ID. Please ensure you have an active subscription."
            case .duplicateTransactionId:
                return "This receipt has already been applied to your account. If you are still not upgraded, contact support for assistance."
            case .noNetwork:
                return "The network appears to be offline."
            case .unknownError:
                return "Unable to reach the server. Please try again."
            case .datanotfound:
                return "No data found."
            case .ipNotAvailable:
                return "Ip1 and ip3 are not available to configure this profile."
            case .missingRemoteAddress:
                return "Missing remote address in selected location."
            case .wgLimitExceeded:
                return "You have reached your limit of WireGuard keys. Do you want to delete your oldest key?"
            case .twoFactorRequired:
                return "2FA code required to login."
            case .tooManyFailedAttempts:
                return "Too many failed attempts. Please wait a moment and try again."
            case .invalid2FA:
                return "Invalid 2FA Code provided."
            case .unspecifiedError:
                return "Unknown error."
            }
        }
    }
}

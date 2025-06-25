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
        static var validationFailure: String {
            return "Invalid session auth or api parameters provided.".localized
        }

        static var invalidSession: String {
            return "Invalid session auth.".localized
        }

        static var unableToUpgradeUser: String {
            return "Failed to process the upgrade using the receipt.".localized
        }

        static var unableToVerifyWithApple: String {
            return "Unable to verify the receipt with Apple.".localized
        }

        static var sandboxReceipt: String {
            return "Windscribe does not support upgrades through the TestFlight version. If you've made a payment during the TestFlight period, rest assured that it won't be charged, as it is solely for testing purposes.".localized
        }

        static var missingTransactionId: String {
            return "Missing transaction ID. Please ensure you have an active subscription.".localized
        }

        static var duplicateTransactionId: String {
            return "This receipt has already been applied to your account. If you are still not upgraded, contact support for assistance.".localized
        }

        static var noNetwork: String {
            return "The network appears to be offline.".localized
        }

        static var unknownError: String {
            return "Unable to reach the server. Please try again.".localized
        }

        static var datanotfound: String {
            return "No data found.".localized
        }

        static var ipNotAvailable: String {
            return "Ip1 and ip3 are not available to configure this profile.".localized
        }

        static var missingRemoteAddress: String {
            return "Missing remote address in selected location.".localized
        }

        static var wgLimitExceeded: String {
            return "You have reached your limit of WireGuard keys. Do you want to delete your oldest key?".localized
        }

        static var twoFactorRequired: String {
            return "2FA code required to login.".localized
        }

        static var tooManyFailedAttempts: String {
            return "Too many failed attempts. Please wait a moment and try again.".localized
        }

        static var invalid2FA: String {
            return "Invalid 2FA Code provided.".localized
        }

        static var unspecifiedError: String {
            return "Unknown error.".localized
        }
    }

}

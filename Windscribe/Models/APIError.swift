//
//  Error.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-12.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation

struct APIError: Equatable {

    let errorCode: Int?
    let errorDescription: String?
    let errorMessage: String?

    init(data: [String: Any]) {
        self.errorCode = data[APIParameters.Errors.errorCode] as? Int
        self.errorDescription = data[APIParameters.Errors.errorDescription] as? String
        self.errorMessage = data[APIParameters.Errors.errorMessage] as? String
    }

    func resolve() -> Error? {
        switch self.errorCode {
        case 501, 502:
            return Errors.validationFailure
        case 503, 600:
            return Errors.userExists
        case 1338:
            return Errors.emailExists
        case 1339:
            return Errors.cannotChangeExistingEmail
        case 701:
            return Errors.sessionIsInvalid
        case 1700:
            return Errors.unableToGenerateCredentials
        case 1340:
            return Errors.twoFactorRequired
        case 1341:
            return Errors.invalid2FA
        case 4004:
            return Errors.unableToUpgradeUser
        case 4006:
            return Errors.unableToVerifyWithApple
        case 4007:
            return Errors.sandboxReceipt
        case 4008:
            return Errors.missingTransactionId
        default:
            return nil
        }
    }

}

enum Errors: Error, CustomStringConvertible, Equatable {
    case notDefined
    case urlBuilding
    case wrongCredentials
    case noResponse
    case noDataReceived
    case sessionIsInvalid
    case validationFailure
    case parsingError
    case userExists
    case emailExists
    case disposableEmail
    case unableToGenerateCredentials
    case missingAuthenticationValues
    case hostnameNotFound
    case noInternetConnection
    case cannotChangeExistingEmail
    case twoFactorRequired
    case invalid2FA
    case unableToConfigure
    case unableToUpgradeUser
    case unableToVerifyWithApple
    case sandboxReceipt
    case missingTransactionId
    case duplicateTransactionId
    case noNetwork
    case unknownError
    case apiError(APIError)
    case datanotfound
    case handled
    case ipNotAvailable
    case missingRemoteAddress

    public var description: String {
        switch self {
        case .validationFailure:
            return "Invalid session auth or api parameters provided."
        case .sessionIsInvalid:
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
        case .apiError(let error):
            return error.errorMessage ?? ""
        case .datanotfound:
            return "no data found."
        case .handled:
            return ""
        case .ipNotAvailable:
            return "Ip1 and ip3 are not avaialble to configure this profile."
        case .missingRemoteAddress:
            return "Missing remote address in selected location."
        default:
            return "Unknown error."
        }
    }
}

//
//  APIError.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-12.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation

struct APIError: Error, Equatable {
    let errorCode: Int?
    let errorDescription: String?
    let errorMessage: String?

    init(data: [String: Any]) {
        errorCode = data[APIParameters.Errors.errorCode] as? Int
        errorDescription = data[APIParameters.Errors.errorDescription] as? String
        errorMessage = data[APIParameters.Errors.errorMessage] as? String
    }

    func resolve() -> Errors? {
        switch errorCode {
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
        case 1313:
            return Errors.wgLimitExceeded
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
    case wgLimitExceeded
    case appleSsoError(String)
    case tooManyFailedAttempts

    public var unlocalizedDescription: String {
        switch self {
        case .validationFailure:
            return ErrorTexts.APIError.validationFailure.unlocalizedDescription
        case .sessionIsInvalid:
            return ErrorTexts.APIError.invalidSession.unlocalizedDescription
        case .unableToUpgradeUser:
            return ErrorTexts.APIError.unableToUpgradeUser.unlocalizedDescription
        case .unableToVerifyWithApple:
            return ErrorTexts.APIError.unableToVerifyWithApple.unlocalizedDescription
        case .sandboxReceipt:
            return ErrorTexts.APIError.sandboxReceipt.unlocalizedDescription
        case .missingTransactionId:
            return ErrorTexts.APIError.missingTransactionId.unlocalizedDescription
        case .duplicateTransactionId:
            return ErrorTexts.APIError.duplicateTransactionId.unlocalizedDescription
        case .noNetwork:
            return ErrorTexts.APIError.noNetwork.unlocalizedDescription
        case .unknownError:
            return ErrorTexts.APIError.unknownError.unlocalizedDescription
        case let .apiError(error):
            return error.errorMessage ?? ""
        case .datanotfound:
            return ErrorTexts.APIError.datanotfound.unlocalizedDescription
        case .handled:
            return ""
        case .ipNotAvailable:
            return ErrorTexts.APIError.ipNotAvailable.unlocalizedDescription
        case .missingRemoteAddress:
            return ErrorTexts.APIError.missingRemoteAddress.unlocalizedDescription
        case .wgLimitExceeded:
            return ErrorTexts.APIError.wgLimitExceeded.unlocalizedDescription
        case .twoFactorRequired:
            return ErrorTexts.APIError.twoFactorRequired.unlocalizedDescription
        case .invalid2FA:
            return ErrorTexts.APIError.invalid2FA.unlocalizedDescription
        case .appleSsoError(let error):
            return error
        case .tooManyFailedAttempts, .parsingError:
            return ErrorTexts.APIError.tooManyFailedAttempts.unlocalizedDescription
        default:
            return ErrorTexts.APIError.unspecifiedError.unlocalizedDescription
        }
    }

    public var description: String {
        unlocalizedDescription.localized
    }
}

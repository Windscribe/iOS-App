//
//  APIManagerImpl+Billing.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-31.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

extension APIManagerImpl {
    func postBillingCpID(pcpID: String) async throws -> APIMessage {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.postBillingCpid(sessionAuth, payCpid: pcpID, callback: completion)
        }
    }

    func getMobileBillingPlans(promo: String?) async throws -> MobilePlanList {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: MobilePlanList.self) { completion in
            self.api.mobileBillingPlans(sessionAuth, mobilePlanType: APIParameterValues.mobilePlanType, promo: promo ?? "", version: APIParameterValues.billingVersion, callback: completion)
        }
    }

    func verifyApplePayment(appleID: String, appleData: String, appleSIG: String) async throws -> APIMessage {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.sendPayment(sessionAuth, appleID: appleID, appleData: appleData, appleSIG: appleSIG, callback: completion)
        }
    }
}

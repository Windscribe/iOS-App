//
//  APIManagerImpl+Billing.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-31.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
extension APIManagerImpl {
    func postBillingCpID(pcpID: String) -> Single<APIMessage> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.postBillingCpid(sessionAuth, payCpid: pcpID, callback: completion)
        }
    }

    func getMobileBillingPlans(promo: String?) -> Single<MobilePlanList> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: MobilePlanList.self) { completion in
            self.api.mobileBillingPlans(sessionAuth, mobilePlanType: APIParameterValues.mobilePlanType, promo: promo ?? "", version: APIParameterValues.billingVersion, callback: completion)
        }
    }

    func verifyApplePayment(appleID: String, appleData: String, appleSIG: String) -> Single<APIMessage> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.sendPayment(sessionAuth, appleID: appleID, appleData: appleData, appleSIG: appleSIG, callback: completion)
        }
    }
}

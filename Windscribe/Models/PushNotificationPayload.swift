//
//  PushNotificationPayload.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-12-23.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
class PushNotificationPayload: Equatable, CustomStringConvertible {
    var description: String {
        return "Type: \(type ?? "") PromoCode: \(promoCode ?? "") Pcpid: \(pcpid ?? "")"
    }

    static func == (lhs: PushNotificationPayload, rhs: PushNotificationPayload) -> Bool {
        return lhs.type == rhs.type && lhs.pcpid == rhs.pcpid && lhs.promoCode == rhs.promoCode
    }

    var type: String?
    var pcpid: String?
    var promoCode: String?

    init(userInfo: [String: AnyObject]) {
        type = userInfo["type"] as? String
        promoCode = userInfo["promo_code"] as? String
        pcpid = userInfo["pcpid"] as? String
    }
}

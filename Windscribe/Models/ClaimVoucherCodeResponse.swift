//
//  ClaimVoucherCodeResponse.swift
//  Windscribe
//
//  Created by Bushra Sagir on 03/10/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

class ClaimVoucherCodeResponse: Decodable {
    let isClaimed: Bool
    let isUsed: Bool
    let isTaken: Bool
    let emailRequired: Bool?

    enum CodingKeys: String, CodingKey {
        case data
        case isClaimed = "voucher_claimed"
        case isUsed = "voucher_used"
        case isTaken = "voucher_taken"
        case emailRequired = "email_required"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        isClaimed = try data.decodeIfPresent(Bool.self, forKey: .isClaimed) ?? false
        isUsed = try data.decodeIfPresent(Bool.self, forKey: .isUsed) ?? false
        isTaken = try data.decodeIfPresent(Bool.self, forKey: .isTaken) ?? false
        emailRequired = try data.decodeIfPresent(Bool.self, forKey: .emailRequired)
    }
}

//
//  BillingRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol BillingRepository {
    func getMobilePlans(promo: String?) -> Single<[MobilePlan]>
}

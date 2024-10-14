//
//  BillingRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
class BillingRepositoryImpl: BillingRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
    }

    func getMobilePlans(promo: String?) -> Single<[MobilePlan]> {
        return apiManager.getMobileBillingPlans(promo: promo).flatMap { plans in
            self.localDatabase.saveMobilePlans(mobilePlansList: plans.mobilePlans.toArray())
            return Single.just(plans.mobilePlans.toArray())
        }.catch { error in
            self.loadFromDatabase(error: error)
        }
    }

    func loadFromDatabase(error: Error) -> Single<[MobilePlan]> {
        return Single.create { single in
            DispatchQueue.main.async {
                if let plans = self.localDatabase.getMobilePlans() {
                    single(.success(plans))
                } else {
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }
}

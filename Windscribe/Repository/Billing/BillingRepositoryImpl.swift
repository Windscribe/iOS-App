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
        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.failure(Errors.validationFailure))
                    return
                }

                do {
                    let plans = try await self.apiManager.getMobileBillingPlans(promo: promo)
                    await MainActor.run {
                        self.localDatabase.saveMobilePlans(mobilePlansList: Array(plans.mobilePlans))
                        single(.success(Array(plans.mobilePlans)))
                    }
                } catch {
                    self.loadFromDatabase(error: error).subscribe(onSuccess: { plans in
                        single(.success(plans))
                    }, onFailure: { dbError in
                        single(.failure(dbError))
                    }).disposed(by: self.disposeBag)
                }
            }

            return Disposables.create {
                task.cancel()
            }
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

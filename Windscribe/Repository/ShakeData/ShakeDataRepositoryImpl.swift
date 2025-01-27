//
//  ShakeDataRepositoryImpl.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

struct ShakeDataRepositoryImpl: ShakeDataRepository {
    private let apiManager: APIManager
    private let sessionManager: SessionManagerV2
    private let disposeBag = DisposeBag()

    init(apiManager: APIManager, sessionManager: SessionManagerV2) {
        self.apiManager = apiManager
        self.sessionManager = sessionManager
    }

    func getLeaderboardScores() -> Single<[Score]> {
        return apiManager.getShakeForDataLeaderboard().flatMap { scoreList in
            Single.just(scoreList.scores)
        }.catch { error in
            Single.error(error)
        }
    }

    func recordShakeForDataScore(score: Int) -> Single<String> {
        guard let userID = sessionManager.session?.userId else {
            return Single.error(Errors.sessionIsInvalid)
        }
        return apiManager.recordShakeForDataScore(score: score, userID: userID).flatMap { apiMessage in
            Single.just(apiMessage.message)
        }.catch { error in
            Single.error(error)
        }
    }
}

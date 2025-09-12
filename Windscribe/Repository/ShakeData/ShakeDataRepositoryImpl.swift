//
//  ShakeDataRepositoryImpl.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class ShakeDataRepositoryImpl: ShakeDataRepository {
    var currentScore: Int = 0

    private let apiManager: APIManager
    private let sessionManager: SessionManager
    private let disposeBag = DisposeBag()

    init(apiManager: APIManager, sessionManager: SessionManager) {
        self.apiManager = apiManager
        self.sessionManager = sessionManager
    }

    func getLeaderboardScores() -> Single<[ShakeForDataScore]> {
        return Single.create { single in
            let task = Task {
                do {
                    let scoreList = try await self.apiManager.getShakeForDataLeaderboard()
                    single(.success(scoreList.scores))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func recordShakeForDataScore(score: Int) -> Single<String> {
        guard let userID = sessionManager.session?.userId else {
            return Single.error(Errors.sessionIsInvalid)
        }

        return Single.create { single in
            let task = Task {
                do {
                    let apiMessage = try await self.apiManager.recordShakeForDataScore(score: score, userID: userID)
                    single(.success(apiMessage.message))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func updateCurrentScore(_ score: Int) {
        currentScore = score
    }
}

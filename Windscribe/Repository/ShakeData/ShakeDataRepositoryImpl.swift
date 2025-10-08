//
//  ShakeDataRepositoryImpl.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

class ShakeDataRepositoryImpl: ShakeDataRepository {
    var currentScore: Int = 0

    private let apiManager: APIManager
    private let sessionManager: SessionManager

    init(apiManager: APIManager, sessionManager: SessionManager) {
        self.apiManager = apiManager
        self.sessionManager = sessionManager
    }

    func getLeaderboardScores() -> AnyPublisher<[ShakeForDataScore], Error> {
        return Future { promise in
            Task {
                do {
                    let scoreList = try await self.apiManager.getShakeForDataLeaderboard()
                    promise(.success(scoreList.scores))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func recordShakeForDataScore(score: Int) -> AnyPublisher<String, Error> {
        guard let userID = sessionManager.session?.userId else {
            return Fail(error: Errors.sessionIsInvalid)
                .eraseToAnyPublisher()
        }

        return Future { promise in
            Task {
                do {
                    let apiMessage = try await self.apiManager.recordShakeForDataScore(score: score, userID: userID)
                    promise(.success(apiMessage.message))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func updateCurrentScore(_ score: Int) {
        currentScore = score
    }
}

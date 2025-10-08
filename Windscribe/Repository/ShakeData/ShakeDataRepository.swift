//
//  ShakeDataRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol ShakeDataRepository {
    var currentScore: Int { get }

    func getLeaderboardScores() -> AnyPublisher<[ShakeForDataScore], Error>
    func recordShakeForDataScore(score: Int) -> AnyPublisher<String, Error>
    func updateCurrentScore(_ score: Int)
}

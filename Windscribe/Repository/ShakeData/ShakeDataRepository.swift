//
//  ShakeDataRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ShakeDataRepository {
    var currentScore: Int { get }

    func getLeaderboardScores() -> Single<[ShakeForDataScore]>
    func recordShakeForDataScore(score: Int) -> Single<String>
    func updateCurrentScore(_ score: Int)
}

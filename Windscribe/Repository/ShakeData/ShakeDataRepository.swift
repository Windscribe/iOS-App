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
    func getLeaderboardScores() -> Single<[Score]>
    func recordShakeForDataScore(score: Int) -> Single<String>
}

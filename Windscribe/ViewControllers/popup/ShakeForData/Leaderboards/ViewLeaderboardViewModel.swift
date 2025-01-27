//
//  ViewLeaderboardViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 23/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

protocol ViewLeaderboardViewModelType {
    var scoresSection: BehaviorRelay<[ScoreSection]> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    func wasShown()
    func load()
}

class ViewLeaderboardViewModel: ViewLeaderboardViewModelType {
    var logger: FileLogger
    var repository: ShakeDataRepository

    var scoresSection = BehaviorRelay<[ScoreSection]>(value: [])
    let isDarkMode: BehaviorSubject<Bool>
    let disposeBag = DisposeBag()

    init(logger: FileLogger, repository: ShakeDataRepository, themeManager: ThemeManager) {
        self.logger = logger
        self.repository = repository
        isDarkMode = themeManager.darkTheme
    }

    func load() {
        repository.getLeaderboardScores().subscribe(onSuccess: { scores in
            self.scoresSection.accept([ScoreSection(items: scores)])
        }, onFailure: { _ in
        }).disposed(by: disposeBag)
    }

    func wasShown() {
        logger.logD(self, "Displaying Shake For Data Leaderboard View")
    }
}

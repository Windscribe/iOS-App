//
//  ShakeForDataResultViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 23/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ShakeForDataResultViewModelType {
    var shakeCount: BehaviorSubject<Int> { get }
    var highestScore: BehaviorSubject<Int> { get }
    var apiMessage: BehaviorSubject<String?> { get }

    func wasShown()
    func quit(from: WSUIViewController, completion: @escaping () -> Void)
    func setup(with shakeCount: Int)
}

class ShakeForDataResultViewModel: ShakeForDataResultViewModelType {
    var logger: FileLogger
    var repository: ShakeDataRepository
    var preferences: Preferences
    var alertManager: AlertManagerV2

    var shakeCount = BehaviorSubject<Int>(value: 0)
    var highestScore = BehaviorSubject<Int>(value: 0)
    var apiMessage = BehaviorSubject<String?>(value: nil)
    let disposeBag = DisposeBag()

    init(logger: FileLogger, repository: ShakeDataRepository, preferences: Preferences, alertManager: AlertManagerV2) {
        self.logger = logger
        self.repository = repository
        self.preferences = preferences
        self.alertManager = alertManager
    }

    func setup(with shakeCount: Int) {
        let highestScore = preferences.getShakeForDataHighestScore() ?? 0
        if shakeCount > highestScore {
            preferences.saveShakeForDataHighestScore(score: shakeCount)
            repository.recordShakeForDataScore(score: shakeCount).subscribe(onSuccess: { message in
                self.apiMessage.onNext(message)
            }, onFailure: { _ in
            }).disposed(by: disposeBag)
        }
        self.shakeCount.onNext(shakeCount)
        self.highestScore.onNext(highestScore)
    }

    func wasShown() {
        logger.logD(self, "Displaying Shake For Data Result View")
    }

    func quit(from: WSUIViewController, completion: @escaping () -> Void) {
        guard let isShakeForDataUnlocked = preferences.getUnlockShakeForData() else { return }
        if isShakeForDataUnlocked {
            completion()
        } else {
            let unlockAction = UIAlertAction(
                title: TextsAsset.ShakeForData.leaveAlertUnlock,
                style: .default) { [weak self ]_ in
                    self?.preferences.saveUnlockShakeForData(bool: true)
                    completion()
            }
            let leaveAction = UIAlertAction(title: TextsAsset.ShakeForData.leaveAlertLeave,
                                            style: .default) { _ in completion() }

            alertManager.showAlert(viewController: from,
                                   title: TextsAsset.ShakeForData.leaveAlertTitle,
                                   message: TextsAsset.ShakeForData.leaveAlertDescription,
                                   actions: [unlockAction, leaveAction])
        }
    }
}

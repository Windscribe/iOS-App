//
//  ShakeForDataResultViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-14.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class ShakeForDataResultViewController: WSUIViewController {
    var backgroundView: UIView!
    var highScoreLabel: UILabel!
    var shakeCounterLabel: UILabel!
    var messageLabel: UILabel!

    var divider: UIView!
    var tryAgainButton, viewLeaderboardButton, quitButton: UIButton!

    var viewModel: ShakeForDataResultViewModelType!
    var popupRouter: PopupRouter!

    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        addAutoLayoutConstraints()
        bindViews()
    }

    private func bindViews() {
        viewModel.wasShown()
        quitButton.rx.tap.bind {
            self.viewModel.quit(from: self) {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }.disposed(by: disposeBag)
        tryAgainButton.rx.tap.bind {
            self.popupRouter.routeTo(to: .shakeForDataView, from: self)
        }.disposed(by: disposeBag)
        viewLeaderboardButton.rx.tap.bind {
            self.popupRouter.routeTo(to: .shakeLeaderboards, from: self)
        }.disposed(by: disposeBag)

        Observable.combineLatest(viewModel.highestScore, viewModel.shakeCount)
            .subscribe(onNext: { highestScore, shakeCount in
                self.claimPrize(highestScore: highestScore, shakeCount: shakeCount)
            }).disposed(by: disposeBag)

        viewModel.shakeCount.subscribe(onNext: {
            self.shakeCounterLabel.text = "\($0)"
        }).disposed(by: disposeBag)

        viewModel.apiMessage.subscribe(onNext: {
            if let message = $0 {
                self.messageLabel.text = message
            }
        }).disposed(by: disposeBag)
    }

    private func claimPrize(highestScore: Int, shakeCount: Int) {
        highScoreLabel.text = "\(TextsAsset.ShakeForData.highScore) \(highestScore)"
        if shakeCount > highestScore {
            highScoreLabel.text = "\(TextsAsset.ShakeForData.newHighScore)"
            highScoreLabel.font = UIFont.bold(size: 24)
        } else {
            messageLabel.text = TextsAsset.ShakeForData.lowerThanHighScoreMessage
        }
    }
}

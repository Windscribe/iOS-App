//
//  ShakeForDataViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import CoreMotion
import RxSwift

class ShakeForDataViewController: WSUIViewController {
    var backgroundView: UIView!
    var fillView: UIView!
    var arrowViewTopLeft, arrowViewTopRight, arrowViewBottomLeft, arrowViewBottomRight: UIImageView!
    var timerIcon: UIImageView!
    var timerLabel: UILabel!
    var shakeCounterLabel: UILabel!
    var shakeInfoLabel: UILabel!
    var quitButton: UIButton!

    var fillViewTopConstraint: NSLayoutConstraint!

    var viewModel: ShakeForDataViewModelType!
    var popupRouter: PopupRouter!

    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        addAutoLayoutConstraints()
        becomeFirstResponder()
        bindViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.wasShown()
    }

    override func setupLocalized() {
        shakeInfoLabel.text = TextsAsset.ShakeForData.shakes
        quitButton.setTitle(TextsAsset.ShakeForData.quit, for: .normal)
    }

    private func bindViews() {
        quitButton.rx.tap.bind {
            self.viewModel.quit()
        }.disposed(by: disposeBag)
        viewModel.timerCount.subscribe(onNext: {
            self.timerLabel.text = "\($0)"
            self.updateUI(timerCount: $0)
        }).disposed(by: disposeBag)
        viewModel.shakeCount.subscribe(onNext: {
            self.shakeCounterLabel.text = "\($0)"
        }).disposed(by: disposeBag)
        viewModel.showResults.subscribe {
            self.popupRouter.routeTo(to: .shakeForDataResult(shakeCount: $0), from: self)
        }.disposed(by: disposeBag)
    }

    private func updateUI(timerCount: Int) {
        UIView.animate(withDuration: 0.1, animations: {
            self.fillViewTopConstraint.constant = (1.0 - CGFloat(timerCount)/CGFloat(self.viewModel.startTimerCount))*self.view.frame.height
            self.view.layoutIfNeeded()
        })
        self.view.layoutIfNeeded()
        if timerCount <= 25 {
            self.timerLabel.textColor = UIColor.backgroundOrange
            self.fillView.backgroundColor = UIColor.backgroundOrange
            self.timerIcon.setImageColor(color: UIColor.backgroundOrange)
        }
        if timerCount <= 5 {
            self.timerLabel.textColor = UIColor.backgroundRed
            self.fillView.backgroundColor = UIColor.backgroundRed
            self.timerIcon.setImageColor(color: UIColor.backgroundRed)
        }
    }

}

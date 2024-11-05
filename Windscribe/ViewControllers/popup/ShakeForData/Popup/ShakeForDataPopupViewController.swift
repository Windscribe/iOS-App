//
//  ShakeForDataPopupViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-12.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class ShakeForDataPopupViewController: WSUIViewController {
    var backgroundView: UIView!
    var imageView: UIImageView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var actionButton: UIButton!
    var cancelButton: UIButton!
    var divider: UIView!
    var viewLeaderboardButton: UIButton!

    var viewModel: ShakeForDataPopupViewModelType!
    var popupRouter: PopupRouter!

    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        addAutoLayoutConstraints()
        bindViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    override func setupLocalized() {
        viewLeaderboardButton.setTitle(TextsAsset.ShakeForData.popupViewLeaderboard, for: .normal)
        cancelButton.setTitle(TextsAsset.ShakeForData.popupCancel, for: .normal)
        actionButton.setTitle(TextsAsset.ShakeForData.popupAction, for: .normal)
        titleLabel.text = TextsAsset.ShakeForData.popupTitle
        descriptionLabel.text = TextsAsset.ShakeForData.popupDescription
    }

    private func bindViews() {
        viewModel.wasShown()
        actionButton.rx.tap.bind {
            self.popupRouter.routeTo(to: .shakeForDataView, from: self)
//            weak var pnvc = self.presentingViewController as? UINavigationController
//            self.dismiss(animated: true, completion: {
//                if let pnvc = pnvc, let pvc = pnvc.topViewController as? WSUIViewController {
//                }
//            })
        }.disposed(by: disposeBag)
        cancelButton.rx.tap.bind {
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        viewLeaderboardButton.rx.tap.bind {
            self.popupRouter.routeTo(to: .shakeLeaderboards, from: self)
        }.disposed(by: disposeBag)
    }
}

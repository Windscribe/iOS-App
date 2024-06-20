//
//  PushNotificationPermissionViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-03-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class PushNotificationViewController: WSUIViewController {

    var backgroundView: UIView!
    var imageView: UIImageView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var actionButton: UIButton!
    var cancelButton: UIButton!

    var viewModel: PushNotificationViewModelType!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addViews()
        self.addAutoLayoutConstraints()
        bindViews()
    }

    private func bindViews() {
        viewModel.wasShown()
        actionButton.rx.tap.bind {
            self.viewModel.action()
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        cancelButton.rx.tap.bind {
            self.viewModel.cancel()
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }
}

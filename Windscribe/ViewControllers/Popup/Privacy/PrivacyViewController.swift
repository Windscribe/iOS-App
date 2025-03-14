//
//  PrivacyViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-09-02.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class PrivacyViewController: WSUIViewController {
    var backgroundView: UIView!
    var descriptionLabel: UILabel!
    var actionButton: UIButton!

    var fontSize: CGFloat = 16

    var viewModel: PrivacyViewModelType!
    var logger: FileLogger!
    var closeCompletion: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Privacy Popup View")
        if UIScreen.isSmallScreen {
            fontSize = 12
        }
        addViews()
        addAutoLayoutConstraints()
        bindViews()
    }

    private func bindViews() {
        actionButton.rx.tap.bind {
            self.dismiss(animated: true, completion: nil)
            self.viewModel.action()
        }.disposed(by: disposeBag)
    }
}

//
//  UntrustedNetworkPopupViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-06-25.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class TrustedNetworkPopupViewController: WSUIViewController {

    var logger: FileLogger!, viewModel: TrustedNetworkPopupType!
    var backgroundView: UIView!
    var imageView: UIImageView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var actionButton: UIButton!
    var cancelButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Trusted Network Popup View")
        self.addViews()
        self.addAutoLayoutConstraints()
        bindViews()
    }

    func bindViews() {
        actionButton.rx.tap.bind { [self] in
            viewModel.trustNetworkAction()
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)

        cancelButton.rx.tap.bind { [self] in
            dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }
}

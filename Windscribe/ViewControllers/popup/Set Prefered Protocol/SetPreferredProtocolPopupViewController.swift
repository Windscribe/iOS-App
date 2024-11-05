//
//  SetPreferredProtocolPopupViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-10-10.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

class SetPreferredProtocolPopupViewController: WSUIViewController {
    var backgroundView: UIView!
    var imageView: UIImageView!
    var titleLabel: UILabel!
    var networkNameLabel: UILabel!
    var descriptionLabel: UILabel!
    var actionButton: UIButton!
    var cancelButton: UIButton!

    var viewModel: SetPreferredProtocolModelType!
    var logger: FileLogger!

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Set Preferred Protocol for Network Popup View")
        addViews()
        addAutoLayoutConstraints()
        bindViews()
    }

    private func bindViews() {
        viewModel.title.bind(to: networkNameLabel.rx.text).disposed(by: disposeBag)

        actionButton.rx.tap.bind { [self] in
            viewModel.action()
            dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)

        cancelButton.rx.tap.bind { [self] in
            viewModel.cancel()
            dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }
}

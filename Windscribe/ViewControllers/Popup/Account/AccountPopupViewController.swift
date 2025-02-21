//
//  AccountPopupViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-20.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import SafariServices
import UIKit

class AccountPopupViewController: WSUIViewController {
    var backgroundView: UIView!
    var imageView: UIImageView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var actionButton: UIButton!
    var cancelButton: UIButton!

    var viewModel: AccountPopupModelType!, logger: FileLogger!

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Account Popup View")
        addViews()
        addAutoLayoutConstraints()
        bindViews()
    }

    private func bindViews() {
        viewModel.imageName.subscribe(onNext: { [self] in
            imageView.image = UIImage(named: $0)
        }).disposed(by: disposeBag)
        viewModel.title.subscribe(onNext: { [self] in
            titleLabel.text = $0
        }).disposed(by: disposeBag)
        viewModel.description.subscribe(onNext: { [self] in
            descriptionLabel.text = $0
        }).disposed(by: disposeBag)
        viewModel.actionButtonTitle.subscribe(onNext: { [self] in
            actionButton.setTitle($0, for: .normal)
            cancelButton.isHidden = $0.isEmpty
        }).disposed(by: disposeBag)
        viewModel.cancelButtonTitle.subscribe(onNext: { [self] in
            cancelButton.setTitle($0, for: .normal)
            cancelButton.isHidden = $0.isEmpty
        }).disposed(by: disposeBag)
    }

    @objc func actionButtonTapped() {
        viewModel.action(viewController: self)
    }

    @objc func cancelButtonTapped() {
        viewModel.cancel(navigationVC: navigationController)
    }
}

class BannedAccountPopupViewController: AccountPopupViewController {}
class OutOfDataAccountPopupViewController: AccountPopupViewController {}
class ProPlanExpiredPopupViewController: AccountPopupViewController {}

//
//  InfoPromptViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-13.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class InfoPromptViewController: WSUIViewController {

    var iconView: UIImageView!
    var infoLabel: UILabel!
    var actionButton: UIButton!
    var cancelButton: UIButton!
    var backgroundView: UIView!

    var viewModel: InfoPromptViewModelType!

    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        addConstraints()
        bindViews()
    }

    private func bindViews() {
        viewModel.title.bind(to: self.infoLabel.rx.text)
            .disposed(by: disposeBag)
        viewModel.actionValue.bind(to: self.actionButton.rx.title(for: .normal))
            .disposed(by: disposeBag)

        actionButton.rx.tap.bind { [self] in
            viewModel.action()
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)

        view.rx.anyGesture(.tap()).skip(1).subscribe(onNext: { [self] _ in
            viewModel.cancel()
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }

}

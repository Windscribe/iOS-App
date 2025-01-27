//
//  ErrorPopupViewController.swift
//  Windscribe
//
//  Created by Thomas on 17/12/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

class ErrorPopupViewController: UIViewController {
    var imageView: UIImageView!
    var messageLabel: UILabel!
    var closeButton: UIButton!

    var viewModel: ErrorPopupViewModelType!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightMidnight

        imageView = UIImageView()
        imageView.image = UIImage(named: ImagesAsset.attention)
        view.addSubview(imageView)

        messageLabel = UILabel()
        messageLabel.font = .text(size: 14)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = .max
        messageLabel.textColor = .backgroundGray
        view.addSubview(messageLabel)

        closeButton = UIButton()
        closeButton.titleLabel?.font = .bold(size: 16)
        closeButton.setTitleColor(UIColor.backgroundGray, for: .normal)
        closeButton.setTitle("Close", for: .normal)
        view.addSubview(closeButton)
        bindView()
    }

    private func bindView() {
        viewModel.message.subscribe(onNext: { [self] in
            self.messageLabel.text = $0
        }).disposed(by: disposeBag)

        closeButton.rx.tap.bind { [self] in
            if viewModel.dismissAction != nil {
                viewModel.dismissAction?()
            } else {
                self.dismiss(animated: true)
            }
        }.disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        imageView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        guard let messageLabel = messageLabel else {
            return
        }
        view.addConstraints([
            .init(item: messageLabel, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 32),
            .init(item: messageLabel, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: -32),
            .init(item: messageLabel, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0),
            .init(item: messageLabel, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1, constant: 16),
        ])
        closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
        closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
}

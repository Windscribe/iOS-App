//
//  CustomConfigListFooterView.swift
//  Windscribe
//
//  Created by Yalcin on 2020-06-30.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import RealmSwift
import RxSwift
import SafariServices
import Swinject
import UIKit

class CustomConfigListFooterView: WSView {
    weak var delegate: AddCustomConfigDelegate?
    lazy var actionButton = UIButton(type: .system)
    lazy var label = UILabel()
    lazy var iconView = UIImageView()
    let disposeBag = DisposeBag()
    lazy var languageManager = Assembler.resolve(LanguageManagerV2.self)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear

        actionButton.backgroundColor = UIColor.clear
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        addSubview(actionButton)

        label.font = UIFont.text(size: 16)
        label.textColor = UIColor.midnight
        label.layer.opacity = 0.4
        addSubview(label)

        iconView.image = UIImage(named: ImagesAsset.externalLink)
        iconView.contentMode = .scaleAspectFit
        iconView.layer.opacity = 0.4
        addSubview(iconView)

        languageManager.activelanguage.subscribe(onNext: { [self] _ in
            label.text = TextsAsset.addCustomConfig
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    override func setupLocalized() {
        label.text = TextsAsset.addCustomConfig
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func actionButtonTapped() {
        delegate?.addCustomConfig()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        layoutViews()
    }

    private func layoutViews() {
        if UIScreen.hasTopNotch {
            addConstraints([
                NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: actionButton, attribute: .centerY, multiplier: 1.0, constant: -10),
                NSLayoutConstraint(item: iconView, attribute: .centerY, relatedBy: .equal, toItem: actionButton, attribute: .centerY, multiplier: 1.0, constant: -10)
            ])
        } else {
            addConstraints([
                NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: actionButton, attribute: .centerY, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: iconView, attribute: .centerY, relatedBy: .equal, toItem: actionButton, attribute: .centerY, multiplier: 1.0, constant: 0)
            ])
        }

        addConstraints([
            NSLayoutConstraint(item: actionButton,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .top,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: actionButton,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .bottom,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: actionButton,
                               attribute: .left,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .left,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: actionButton,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .right,
                               multiplier: 1.0,
                               constant: 0)
        ])
        addConstraints([
            NSLayoutConstraint(item: label,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: iconView,
                               attribute: .left,
                               multiplier: 1.0,
                               constant: -10),
            NSLayoutConstraint(item: label,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .height,
                               multiplier: 1.0,
                               constant: 20)
        ])
        addConstraints([
            NSLayoutConstraint(item: iconView,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: actionButton,
                               attribute: .right,
                               multiplier: 1.0,
                               constant: -12),
            NSLayoutConstraint(item: iconView,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .height,
                               multiplier: 1.0,
                               constant: 16),
            NSLayoutConstraint(item: iconView,
                               attribute: .width,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .width,
                               multiplier: 1.0,
                               constant: 16)
        ])
    }
}

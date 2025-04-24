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
    let disposeBag = DisposeBag()
    lazy var languageManager = Assembler.resolve(LanguageManagerV2.self)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .whiteWithOpacity(opacity: 0.05)

        actionButton.backgroundColor = UIColor.clear
        addSubview(actionButton)

        label.font = UIFont.text(size: 16)
        label.textColor = UIColor.cyberBlue
        label.layer.opacity = 0.7
        addSubview(label)

        actionButton.rx.tap.bind { [weak self] _ in
            self?.delegate?.addCustomConfig()
        }.disposed(by: disposeBag)

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

        layoutViews()
    }

    private func layoutViews() {
        let centerYConstant = UIScreen.hasTopNotch ? -10.0 : 0.0
        NSLayoutConstraint.activate([
            // label
            label.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor, constant: centerYConstant),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.heightAnchor.constraint(equalToConstant: 21),

            // actionButton
            actionButton.topAnchor.constraint(equalTo: topAnchor),
            actionButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            actionButton.leftAnchor.constraint(equalTo: leftAnchor),
            actionButton.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }
}

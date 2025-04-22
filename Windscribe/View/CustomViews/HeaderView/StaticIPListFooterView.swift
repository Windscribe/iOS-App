//
//  StaticIPListFooterView.swift
//  Windscribe
//
//  Created by Yalcin on 2019-03-12.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RealmSwift
import RxSwift
import SafariServices
import Swinject
import UIKit

class StaticIPListFooterView: WSView {
    weak var delegate: StaticIPListFooterViewDelegate?
    lazy var actionButton = UIButton(type: .system)
    lazy var deviceNameLabel = UILabel()
    lazy var label = UILabel()
    var viewModel: MainViewModelType?
    let disposeBag = DisposeBag()
    lazy var languageManager = Assembler.resolve(LanguageManagerV2.self)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .whiteWithOpacity(opacity: 0.05)

        actionButton.backgroundColor = .clear
        addSubview(actionButton)

        deviceNameLabel.font = UIFont.text(size: 16)
        deviceNameLabel.textColor = UIColor.white
        deviceNameLabel.layer.opacity = 0.7
        addSubview(deviceNameLabel)

        label.font = UIFont.text(size: 16)
        label.textColor = UIColor.actionGreen
        label.layer.opacity = 0.7
        addSubview(label)

        viewModel?.staticIPs.subscribe { [weak self] _ in
            self?.updateDeviceName()
        }.disposed(by: disposeBag)
        actionButton.rx.tap.bind { [weak self] _ in
            self?.delegate?.addStaticIP()
        }.disposed(by: disposeBag)
        languageManager.activelanguage.subscribe { [weak self] _ in
            self?.label.text = TextsAsset.addStaticIP
        }.disposed(by: disposeBag)
    }

    override func setupLocalized() {
        label.text = TextsAsset.addStaticIP
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateDeviceName() {
        DispatchQueue.main.async { [self] in
            self.deviceNameLabel.text = self.viewModel?.getStaticIp().first?.getStaticIPModel()?.deviceName
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        deviceNameLabel.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        let centerYConstant = UIScreen.hasTopNotch ? -10.0 : 0.0
        NSLayoutConstraint.activate([
            // label
            label.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor, constant: centerYConstant),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            label.heightAnchor.constraint(equalToConstant: 21),

            // deviceNameLabel
            deviceNameLabel.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor, constant: centerYConstant),
            deviceNameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            deviceNameLabel.heightAnchor.constraint(equalToConstant: 21),

            // actionButton
            actionButton.topAnchor.constraint(equalTo: topAnchor),
            actionButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            actionButton.leftAnchor.constraint(equalTo: leftAnchor),
            actionButton.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }
}

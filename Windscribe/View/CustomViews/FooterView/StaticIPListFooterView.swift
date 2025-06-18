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
    lazy var backgroundView = UIView()
    lazy var languageManager = Assembler.resolve(LanguageManager.self)
    let disposeBag = DisposeBag()
    var viewModel: MainViewModelType? {
        didSet {
            bindViews()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(backgroundView)

        actionButton.backgroundColor = .clear
        addSubview(actionButton)

        deviceNameLabel.font = UIFont.text(size: 16)
        deviceNameLabel.layer.opacity = 0.7
        addSubview(deviceNameLabel)

        label.font = UIFont.text(size: 16)
        label.textColor = UIColor.cyberBlue
        label.layer.opacity = 0.7
        addSubview(label)
    }

    private func bindViews() {
        viewModel?.staticIPs.subscribe { [weak self] _ in
            self?.updateDeviceName()
        }.disposed(by: disposeBag)
        actionButton.rx.tap.bind { [weak self] _ in
            self?.delegate?.addStaticIP()
        }.disposed(by: disposeBag)
        languageManager.activelanguage.subscribe { [weak self] _ in
            self?.label.text = TextsAsset.addStaticIP
        }.disposed(by: disposeBag)
        viewModel?.isDarkMode.subscribe { [weak self] isDarkMode in
            self?.backgroundView.backgroundColor = .from(.pressStateColor, isDarkMode)
            self?.backgroundColor = .from(.backgroundColor, isDarkMode)
            self?.deviceNameLabel.textColor = .from(.textColor, isDarkMode)
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
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        let centerYConstant = UIScreen.hasTopNotch ? -10.0 : 0.0
        NSLayoutConstraint.activate([
            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.rightAnchor.constraint(equalTo: rightAnchor),
            backgroundView.leftAnchor.constraint(equalTo: leftAnchor),

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

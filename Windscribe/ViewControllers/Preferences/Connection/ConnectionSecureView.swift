//
//	ConnectionSecureView.swift
//	Windscribe
//
//	Created by Thomas on 24/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class ConnectionSecureView: UIView {
    var isDarkMode: BehaviorSubject<Bool>

    lazy var contentView = UIView()
    lazy var backgroundView = UIView()
    lazy var squareView = UIImageView()
    lazy var titleLabel = UILabel()
    lazy var subTitleLabel = UILabel()
    lazy var iconView = UIImageView()
    lazy var switchButton = SwitchButton(isDarkMode: isDarkMode)

    var connectionSecureViewSwitchAcction: (() -> Void)?
    var explainHandler: (() -> Void)?

    private let disposeBag = DisposeBag()
    private let imageSetTrigger = PublishSubject<()>()

    init(isDarkMode: BehaviorSubject<Bool>) {
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        configViews()
        layoutViews()
        bindViews()
    }

    private func layoutViews() {
        addSubview(contentView)
        contentView.makeLeadingAnchor()
        contentView.makeTrailingAnchor()
        contentView.makeTopAnchor()
        contentView.makeBottomAnchor()

        contentView.addSubview(backgroundView)
        backgroundView.makeTopAnchor(constant: 2)
        backgroundView.makeLeadingAnchor(constant: 2)
        backgroundView.makeTrailingAnchor(constant: 2)

        backgroundView.addSubview(squareView)
        squareView.makeCenterYAnchor()
        squareView.makeHeightAnchor(equalTo: 16)
        squareView.makeWidthAnchor(equalTo: 16)
        squareView.makeLeadingAnchor(constant: 16)

        backgroundView.addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: squareView.trailingAnchor, constant: 16).isActive = true
        titleLabel.makeTopAnchor(constant: 16)
        titleLabel.makeBottomAnchor(constant: 16)

        backgroundView.addSubview(switchButton)
        switchButton.layer.cornerRadius = 12
        switchButton.clipsToBounds = true
        switchButton.makeCenterYAnchor()
        switchButton.makeTrailingAnchor(constant: 16)
        switchButton.makeHeightAnchor(equalTo: 25)
        switchButton.makeWidthAnchor(equalTo: 45)
        switchButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16).isActive = true

        contentView.addSubview(subTitleLabel)
        subTitleLabel.makeLeadingAnchor(constant: 16)
        subTitleLabel.makeTopAnchor(with: backgroundView, constant: 16)
        subTitleLabel.makeBottomAnchor(constant: 16)
        subTitleLabel.makeTrailingAnchor(constant: 32)
        subTitleLabel.numberOfLines = 0

        contentView.addSubview(iconView)
//        iconView.centerYAnchor.constraint(equalTo: subTitleLabel.centerYAnchor).isActive = true
        iconView.makeTrailingAnchor(constant: 16)
        iconView.makeHeightAnchor(equalTo: 16)
        iconView.makeWidthAnchor(equalTo: 16)
        iconView.makeTopAnchor(with: backgroundView, constant: 16)
    }

    private func configViews() {
        backgroundColor = .clear
        layer.cornerRadius = 8

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 2

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.layer.cornerRadius = 6

        squareView.translatesAutoresizingMaskIntoConstraints = false
        squareView.layer.borderWidth = 2
        squareView.backgroundColor = .clear

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        titleLabel.font = UIFont.bold(size: 16)

        subTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subTitleLabel.layer.opacity = 0.5
        subTitleLabel.font = UIFont.text(size: 14)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(named: "learn-more-ic")
        iconView.layer.opacity = 0.5
        iconView.isUserInteractionEnabled = true
        iconView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        iconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iconExplainTapped)))

        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        switchButton.addTarget(self, action: #selector(switchButtonTapped), for: .touchUpInside)
    }

    @objc private func iconExplainTapped() {
        explainHandler?()
    }

    @objc func switchButtonTapped() {
        switchButton.toggle()
        connectionSecureViewSwitchAcction?()
    }

    private func bindViews() {
        Observable.combineLatest(imageSetTrigger, isDarkMode).bind { (_, isDark) in
            self.updateTheme(isDark: isDark)
        }.disposed(by: disposeBag)
    }

    func setImage(_ image: UIImage?) {
        if let image = image {
            squareView.image = image
            squareView.layer.borderWidth = 0
            imageSetTrigger.onNext(())
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTheme(isDark: Bool) {
        squareView.updateTheme(isDark: isDark)
        iconView.updateTheme(isDark: isDark)
        switchButton.updateTheme(isDark: isDark)
        contentView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark).cgColor
        backgroundView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark)
        squareView.layer.borderColor = ThemeUtils.primaryTextColor(isDarkMode: isDark).cgColor
        titleLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
        subTitleLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
    }

    func udpateStringData(title: String, subTitle: String) {
        self.titleLabel.text = title
        self.subTitleLabel.text = subTitle
    }

    func hideShowExplainIcon(_ isHidden: Bool = true) {
        iconView.isHidden = isHidden
    }
}

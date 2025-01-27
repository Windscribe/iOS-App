//
//	RobertHeaderView.swift
//	Windscribe
//
//	Created by Thomas on 23/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject
import UIKit

class RobertHeaderView: UIView {
    lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 8
        return view
    }()

    lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = Robert.description
        descriptionLabel.font = UIFont.text(size: 12)
        descriptionLabel.layer.opacity = 0.5
        descriptionLabel.numberOfLines = 0
        return descriptionLabel
    }()

    lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "learn-more-ic")
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        view.makeHeightAnchor(equalTo: 16)
        view.makeWidthAnchor(equalTo: 16)
        return view
    }()

    var contentViewAction: (() -> Void)?
    private let disposeBag = DisposeBag()

    @objc func contentViewTapped() {
        contentViewAction?()
    }

    init(isDarkMode: BehaviorSubject<Bool>) {
        super.init(frame: .zero)
        setupViews()
        bindViews(isDarkMode: isDarkMode)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe {
            self.contentView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0).cgColor
            self.descriptionLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
        }.disposed(by: disposeBag)
    }

    private func setupViews() {
        backgroundColor = .clear

        contentView.addTapGesture(tapNumber: 1, target: self, action: #selector(contentViewTapped))

        addSubview(contentView)
        contentView.makeTopAnchor(constant: 16)
        contentView.makeBottomAnchor(constant: 8)
        contentView.makeLeadingAnchor()
        contentView.makeTrailingAnchor()

        contentView.addSubview(descriptionLabel)
        descriptionLabel.makeTopAnchor(constant: 16)
        descriptionLabel.makeLeadingAnchor(constant: 16)
        descriptionLabel.makeBottomAnchor(constant: 16)

        contentView.addSubview(iconView)
        iconView.makeCenterYAnchor()
        iconView.makeTrailingAnchor(constant: 16)
        iconView.leadingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor, constant: 16).isActive = true
    }
}

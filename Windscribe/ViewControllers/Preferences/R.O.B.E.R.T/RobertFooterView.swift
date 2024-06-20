//
//	RobertFooterView.swift
//	Windscribe
//
//	Created by Thomas on 23/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import RxSwift

class RobertFooterView: WSTouchView {
    lazy var contentView = UIView()
    lazy var titleLabel = UILabel()
    lazy var iconView = UIImageView()
    let isHighlightedSubject = BehaviorSubject<Bool>(value: false)
    private let disposeBag = DisposeBag()

    init(isDarkMode: BehaviorSubject<Bool>) {
        super.init(frame: .zero)

        setupViews()

        addSubview(contentView)
        contentView.makeLeadingAnchor()
        contentView.makeTrailingAnchor()
        contentView.makeTopAnchor(constant: 8)
        contentView.makeBottomAnchor(constant: 16)

        contentView.addSubview(titleLabel)
        titleLabel.makeTopAnchor(constant: 16)
        titleLabel.makeLeadingAnchor(constant: 16)
        titleLabel.makeBottomAnchor(constant: 16)

        contentView.addSubview(iconView)
        iconView.makeCenterYAnchor()
        iconView.makeHeightAnchor(equalTo: 16)
        iconView.makeWidthAnchor(equalTo: 16)
        iconView.makeTrailingAnchor(constant: 16)

        bindViews(isDarkMode: isDarkMode)
    }

    var contentViewAction: (() -> Void)?

    @objc func contentViewTapped() {
        contentViewAction?()
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe( onNext: { [weak self] in
            guard let self = self else { return }
            self.contentView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
            self.iconView.image = ThemeUtils.iconViewImage(isDarkMode: $0)
            self.titleLabel.textColor = ThemeUtils.getRobertTextColor(isDarkMode: $0)
        }).disposed(by: disposeBag)

        Observable.combineLatest(isHighlightedSubject.asObservable(), isDarkMode.asObservable()).bind { (isHighlighted, isDarkMode) in
            self.titleLabel.textColor = isHighlighted ? ThemeUtils.primaryTextColor(isDarkMode: isDarkMode) : ThemeUtils.getRobertTextColor(isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)
    }

    private func setupViews() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layer.cornerRadius = 8
        contentView.addTapGesture(tapNumber: 1, target: self, action: #selector(contentViewTapped))

        titleLabel.text = TextsAsset.Robert.manageCustomRules
        titleLabel.font = UIFont.bold(size: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        iconView.layer.opacity = 0.25
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
    }

    override func configNormal() {
        isHighlightedSubject.onNext(false)
        iconView.layer.opacity = 0.25
    }
    override func configHighlight() {
        isHighlightedSubject.onNext(true)
        iconView.layer.opacity = 1
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

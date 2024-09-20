//
//  RobertFilterCell.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-12-16.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

class RobertFilterCell: UITableViewCell {
    lazy var wrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        return view
    }()
    var centerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.makeHeightAnchor(equalTo: 4)
        return view
    }()
    lazy var titleLabel = UILabel()
    lazy var statusLabel = UILabel()
    var filterSwitchTapArea = UIButton()
    lazy var filterSwitch: SwitchButton = SwitchButton(isDarkMode: isDarkMode)
    lazy var icon = UIImageView()

    var robertFilter: RobertFilter? {
        didSet {
            updateUI()
        }
    }

    var isDarkMode = BehaviorSubject<Bool>(value: false)

    private let isEnabledTrigger = PublishSubject<Bool>()
    private let disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    func setupSubviews(isDarkMode: BehaviorSubject<Bool>) {
        self.isDarkMode = isDarkMode
        backgroundColor = .clear
        contentView.isUserInteractionEnabled = true

        icon.contentMode = .scaleAspectFit
        addSubview(icon)

        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.bold(size: 16)
        titleLabel.textAlignment = .left
        addSubview(titleLabel)

        statusLabel.textColor = UIColor.white
        statusLabel.font = UIFont.text(size: 12)
        statusLabel.textAlignment = .left
        addConstraints()
        bindViews(isDarkMode: isDarkMode)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        addConstraints()
    }

    private func addConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        filterSwitch.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        filterSwitchTapArea.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(wrapperView)
        wrapperView.makeTopAnchor(constant: 8)
        wrapperView.makeBottomAnchor(constant: 8)
        wrapperView.makeLeadingAnchor()
        wrapperView.makeTrailingAnchor()

        wrapperView.addSubview(icon)
        icon.makeLeadingAnchor(constant: 16)
        icon.makeCenterYAnchor()
        icon.makeHeightAnchor(equalTo: 16)
        icon.makeWidthAnchor(equalTo: 16)

        wrapperView.addSubview(centerView)
        centerView.leadingAnchor.constraint(equalTo: icon.trailingAnchor).isActive = true
        centerView.centerYAnchor.constraint(equalTo: icon.centerYAnchor).isActive = true
        centerView.makeTrailingAnchor()

        wrapperView.addSubview(titleLabel)
        titleLabel.makeTopAnchor(constant: 16)
        titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16).isActive = true
        titleLabel.makeBottomAnchor(with: centerView)

        wrapperView.addSubview(statusLabel)
        statusLabel.makeTopAnchor(with: centerView)
        statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        statusLabel.makeBottomAnchor(constant: 16)

        wrapperView.addSubview(filterSwitch)
        filterSwitch.makeHeightAnchor(equalTo: 24)
        filterSwitch.makeWidthAnchor(equalTo: 45)
        filterSwitch.makeTrailingAnchor(constant: 16)
        filterSwitch.makeCenterYAnchor()
        filterSwitch.layer.cornerRadius = 12
        filterSwitch.clipsToBounds = true

        wrapperView.addSubview(filterSwitchTapArea)
        filterSwitchTapArea.leadingAnchor.constraint(equalTo: filterSwitch.leadingAnchor).isActive = true
        filterSwitchTapArea.trailingAnchor.constraint(equalTo: filterSwitch.trailingAnchor).isActive = true
        filterSwitchTapArea.heightAnchor.constraint(equalTo: wrapperView.heightAnchor).isActive = true
        filterSwitchTapArea.centerYAnchor.constraint(equalTo: wrapperView.centerYAnchor).isActive = true
    }

    func updateUI() {
        if let item = robertFilter {
            titleLabel.text = item.title
            filterSwitch.status = item.enabled
            if item.enabled {
                statusLabel.text = TextsAsset.Robert.blocking
                statusLabel.layer.opacity = 1
            } else {
                statusLabel.layer.opacity = 0.5
                statusLabel.text = TextsAsset.Robert.allowing
            }
            isEnabledTrigger.onNext(item.enabled)
        }
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        Observable.combineLatest(isEnabledTrigger.asObservable(), isDarkMode.asObservable()).bind { (isEnabled, isDarkMode) in
            if isDarkMode {
                self.titleLabel.textColor = UIColor.white
                if let item = self.robertFilter, self.robertFilter?.isInvalidated == false {
                    self.icon.image = UIImage(named: ImagesAsset.DarkMode.filterIcons[item.id] ?? "unknown_robert_category-white")
                }
            } else {
                self.titleLabel.textColor = UIColor.midnight
                if let item = self.robertFilter, self.robertFilter?.isInvalidated == false {
                    self.icon.image = UIImage(named: ImagesAsset.Robert.filterIcons[item.id] ?? "unknown_robert_category")
                }
            }
            self.statusLabel.textColor = isEnabled ? UIColor.green : ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            self.wrapperView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)
    }
}

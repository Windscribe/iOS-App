//
//  PreferencesTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-01.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class PreferencesTableViewCell: WSTouchTableViewCell {
    var iconView = UIImageView()
    var titleLabel = UILabel()
    var arrowIcon = UIImageView()
    var cellDivider = UIView()
    let disposeBag = DisposeBag()
    var displayingItem: PreferenceItem? {
        didSet {
            updateUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear

        iconView.contentMode = .scaleAspectFit

        addSubview(iconView)

        titleLabel.textColor = UIColor.white
        titleLabel.layer.opacity = 0.5
        titleLabel.font = UIFont.bold(size: 16)
        titleLabel.textAlignment = .left

        addSubview(titleLabel)
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.layer.opacity = 0.5
        arrowIcon.image = UIImage(named: ImagesAsset.prefRightIcon)
        addSubview(arrowIcon)

        cellDivider.backgroundColor = UIColor.white
        cellDivider.layer.opacity = 0.05
        addSubview(cellDivider)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func configNormal() {
        titleLabel.layer.opacity = 0.5
        arrowIcon.layer.opacity = 0.5
    }

    override func configHighlight() {
        titleLabel.layer.opacity = 1
        arrowIcon.layer.opacity = 1
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        selectedBackgroundView?.frame = CGRect(x: 0, y: -4, width: frame.width, height: frame.height + 4)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        cellDivider.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: iconView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: iconView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: iconView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: iconView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16)
        ])
        addConstraints([
            NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: iconView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: iconView, attribute: .right, multiplier: 1.0, constant: 14),
            NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20)
        ])
        addConstraints([
            NSLayoutConstraint(item: arrowIcon, attribute: .centerY, relatedBy: .equal, toItem: iconView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: arrowIcon, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: arrowIcon, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: arrowIcon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16)
        ])
        addConstraints([
            NSLayoutConstraint(item: cellDivider, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -2),
            NSLayoutConstraint(item: cellDivider, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: cellDivider, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cellDivider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2)
        ])
    }

    func updateUI() {
        if let title = displayingItem?.title {
            titleLabel.text = title
        }
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(onNext: { isDarkMode in
            if !isDarkMode {
                self.cellDivider.backgroundColor = UIColor.midnight
                self.titleLabel.textColor = UIColor.midnight
                if let icon = self.displayingItem?.icon {
                    self.iconView.image = UIImage(named: "\(icon)")
                }
                self.arrowIcon.image = UIImage(named: ImagesAsset.prefRightIcon)
            } else {
                self.cellDivider.backgroundColor = UIColor.white
                self.titleLabel.textColor = UIColor.white
                if let icon = self.displayingItem?.icon {
                    self.iconView.image = UIImage(named: "\(icon)-white")
                }
                self.arrowIcon.image = UIImage(named: ImagesAsset.DarkMode.prefRightIcon)
            }
        }).disposed(by: disposeBag)
    }
}

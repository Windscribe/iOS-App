//
//  HelpViewCell.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-06-24.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import UIKit

class HelpViewCell: UITableViewCell {

    var iconImage = UIImageView()
    var titleLabel = UILabel()
    var subTitleLabel = UILabel()
    var arrowIcon = UIImageView()
    var cellDivider = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        iconImage.contentMode = .scaleAspectFit
        iconImage.tintColor = UIColor.white
        iconImage.image = UIImage(named: ImagesAsset.rightArrow)?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        addSubview(iconImage)

        titleLabel.textColor = UIColor.white
        titleLabel.layer.opacity = 0.5
        titleLabel.font = UIFont.bold(size: 16)
        titleLabel.textAlignment = .left
        addSubview(titleLabel)

        subTitleLabel.textColor = UIColor.white
        subTitleLabel.layer.opacity = 0.5
        subTitleLabel.lineBreakMode = .byCharWrapping
        subTitleLabel.numberOfLines = 0
        subTitleLabel.font = UIFont.text(size: 12)
        subTitleLabel.textAlignment = .left
        addSubview(subTitleLabel)

        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.image = UIImage(named: ImagesAsset.rightArrow)?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        arrowIcon.tintColor = UIColor.white
        addSubview(arrowIcon)

        cellDivider.backgroundColor = UIColor.white
        cellDivider.layer.opacity = 0.05
        addSubview(cellDivider)

        backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.displayForPrefferedAppearence()

        iconImage.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        cellDivider.translatesAutoresizingMaskIntoConstraints = false

        var arrowIconConstraints = [
            arrowIcon.centerYAnchor.constraint(equalTo: iconImage.centerYAnchor, constant: 0),
            arrowIcon.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12),
            arrowIcon.widthAnchor.constraint(equalToConstant: 16),
            arrowIcon.heightAnchor.constraint(equalToConstant: 16)
        ]
        let titleLabelContraints = [
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 40)
        ]
        let iconImageContraints = [
            iconImage.centerYAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            iconImage.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            iconImage.widthAnchor.constraint(equalToConstant: 16),
            iconImage.heightAnchor.constraint(equalToConstant: 16)
        ]
        let subTitleLabelContraints = [
            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subTitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
            subTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -32)
        ]
        var cellDividerContraints = [
            cellDivider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            cellDivider.leftAnchor.constraint(equalTo: iconImage.leftAnchor, constant: 8),
            cellDivider.rightAnchor.constraint(equalTo: self.rightAnchor),
            cellDivider.heightAnchor.constraint(equalToConstant: 2)
        ]

        NSLayoutConstraint.activate(titleLabelContraints)
        NSLayoutConstraint.activate(iconImageContraints)
        if let item = helpItem {
            if item.subTitle.isEmpty {
                iconImage.isHidden = true
                cellDividerContraints[0] = cellDivider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12)
                cellDividerContraints[1] = cellDivider.leftAnchor.constraint(equalTo: item.title == Help.discord ? iconImage.centerXAnchor :  titleLabel.leftAnchor)
                arrowIconConstraints[0] = arrowIcon.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
                NSLayoutConstraint.deactivate(subTitleLabelContraints)
            } else {
                iconImage.isHidden = false
                NSLayoutConstraint.activate(subTitleLabelContraints)
            }

            if item.hideDivider {
                arrowIcon.isHidden = true
                NSLayoutConstraint.deactivate(cellDividerContraints)
            } else {
                NSLayoutConstraint.activate(cellDividerContraints)
            }
            cellDivider.isHidden = item.hideDivider
            NSLayoutConstraint.activate(arrowIconConstraints)
        }
    }
    var helpItem: HelpItem? {
        didSet {
            updateUI()
        }
    }

    func updateUI() {
        if let item = helpItem {
            subTitleLabel.text = item.subTitle
            iconImage.image = UIImage(named: item.icon)?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            if item.subTitle.isEmpty {
                titleLabel.font = UIFont.text(size: 16)
            }
           titleLabel.setTextWithOffSet(text: item.title)
        }
    }

    func displayForPrefferedAppearence() {
        let isDark = themeManager.getIsDarkTheme()
        if !isDark {
            cellDivider.backgroundColor = UIColor.midnight
            let bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.seperatorGray
            selectedBackgroundView = bgColorView
            titleLabel.textColor = UIColor.midnight
            arrowIcon.image = UIImage(named: ImagesAsset.prefRightIcon)
            iconImage.tintColor = UIColor.midnight
            subTitleLabel.textColor = UIColor.midnight
        } else {
            cellDivider.backgroundColor = UIColor.white
            let bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.seperatorWhite
            selectedBackgroundView = bgColorView
            titleLabel.textColor = UIColor.white
            arrowIcon.image = UIImage(named: ImagesAsset.DarkMode.prefRightIcon)
            iconImage.tintColor = UIColor.white
            subTitleLabel.textColor = UIColor.white
        }
    }
}

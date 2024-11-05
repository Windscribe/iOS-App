//
//  IAPInfoSectionCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-28.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

class IAPInfoSectionCell: UITableViewCell {
    var checkMarkIconView = UIImageView()
    var titleLabel = UILabel()
    var expandIconView = UIImageView()
    var bottomSeperatorView = UIView()
    var section: Int = 0
    var displayingSection: IAPInfoSection? {
        didSet {
            updateUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.clear

        checkMarkIconView.image = UIImage(named: ImagesAsset.greenCheckMark)
        addSubview(checkMarkIconView)

        titleLabel.font = UIFont.bold(size: 14)
        titleLabel.textColor = UIColor.white
        addSubview(titleLabel)

        expandIconView.image = UIImage(named: ImagesAsset.whiteExpand)
        addSubview(expandIconView)

        bottomSeperatorView.backgroundColor = UIColor.white
        bottomSeperatorView.layer.opacity = 0.15
        addSubview(bottomSeperatorView)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        checkMarkIconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        expandIconView.translatesAutoresizingMaskIntoConstraints = false
        bottomSeperatorView.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: checkMarkIconView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: checkMarkIconView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: checkMarkIconView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: checkMarkIconView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
        ])
        addConstraints([
            NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: checkMarkIconView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 18),
            NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: checkMarkIconView, attribute: .right, multiplier: 1.0, constant: 16),
        ])
        addConstraints([
            NSLayoutConstraint(item: expandIconView, attribute: .centerY, relatedBy: .equal, toItem: checkMarkIconView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: expandIconView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: expandIconView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: expandIconView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
        ])
        addConstraints([
            NSLayoutConstraint(item: bottomSeperatorView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -2),
            NSLayoutConstraint(item: bottomSeperatorView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: bottomSeperatorView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: bottomSeperatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
        ])
    }

    func updateUI() {
        if let title = displayingSection?.title {
            titleLabel.text = title
        }
    }

    func setCollapsed(collapsed: Bool, completion _: @escaping () -> Void = {}) {
        if collapsed { showForCollapse() } else { showForExpand() }
    }

    func expand(completion: @escaping () -> Void = {}) {
        expandIconView.layer.opacity = 1.0
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.expandIconView.transform = CGAffineTransform(rotationAngle: .pi / 4)
        }, completion: { _ in
            completion()
        })
    }

    func showForExpand() {
        expandIconView.layer.opacity = 1.0
        expandIconView.transform = CGAffineTransform(rotationAngle: .pi / 4)
    }

    func collapse(completion: @escaping () -> Void = {}) {
        expandIconView.layer.opacity = 0.4
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.expandIconView.transform = CGAffineTransform(rotationAngle: .pi * 4)
        }, completion: { _ in
            completion()
        })
    }

    func showForCollapse() {
        expandIconView.layer.opacity = 0.4
        expandIconView.transform = CGAffineTransform(rotationAngle: .pi * 4)
    }
}

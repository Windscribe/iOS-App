//
//  IAPInfoCellTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-28.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

class IAPInfoCellTableViewCell: UITableViewCell {
    var messageLabel = UILabel()
    var displayingSection: IAPInfoSection? {
        didSet {
            updateUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.clear

        messageLabel.font = UIFont.text(size: 14)
        messageLabel.numberOfLines = 0
        messageLabel.textColor = UIColor.white
        messageLabel.layer.opacity = 0.5
        addSubview(messageLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: messageLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: messageLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 48),
            NSLayoutConstraint(item: messageLabel, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -48),
        ])
    }

    func updateUI() {
        if let message = displayingSection?.message {
            messageLabel.text = message
        }
    }
}

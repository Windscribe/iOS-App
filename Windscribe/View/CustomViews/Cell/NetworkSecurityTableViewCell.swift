//
//  NetworkSecurityTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-05.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

protocol NetworkSecurityTableViewCellDelegate: AnyObject {
    func showNetworkList(indexPath: IndexPath)
}

class NetworkSecurityTableViewCell: UITableViewCell {
    weak var delegate: NetworkSecurityTableViewCellDelegate?
    var nameLabel = UILabel()
    var trustStatusLabel = UILabel()
    var arrowIcon = UIImageView()
    var cellDivider = UIView()
    var displayingWifiNetwork: WifiNetwork? {
        didSet {
            updateUI()
        }
    }

    var indexPath: IndexPath?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.clear

        nameLabel.textColor = UIColor.white
        nameLabel.font = UIFont.bold(size: 16)
        nameLabel.textAlignment = .left
        addSubview(nameLabel)

        trustStatusLabel.textColor = UIColor.white
        trustStatusLabel.font = UIFont.text(size: 16)
        trustStatusLabel.textAlignment = .left
        trustStatusLabel.layer.opacity = 0.5
        addSubview(trustStatusLabel)

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

    override func layoutSubviews() {
        super.layoutSubviews()
        displayForPrefferedAppearence()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        trustStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        cellDivider.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: nameLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: nameLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: nameLabel, attribute: .right, relatedBy: .equal, toItem: trustStatusLabel, attribute: .left, multiplier: 0.95, constant: -16),
            NSLayoutConstraint(item: nameLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
        ])
        addConstraints([
            NSLayoutConstraint(item: trustStatusLabel, attribute: .centerY, relatedBy: .equal, toItem: nameLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: trustStatusLabel, attribute: .right, relatedBy: .equal, toItem: arrowIcon, attribute: .left, multiplier: 1.0, constant: -8),
            NSLayoutConstraint(item: trustStatusLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
        ])
        addConstraints([
            NSLayoutConstraint(item: arrowIcon, attribute: .centerY, relatedBy: .equal, toItem: nameLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: arrowIcon, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: arrowIcon, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: arrowIcon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
        ])
        addConstraints([
            NSLayoutConstraint(item: cellDivider, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cellDivider, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: cellDivider, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cellDivider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
        ])
    }

    func updateUI() {
        guard let wifiNetwork = displayingWifiNetwork else { return }
        nameLabel.text = wifiNetwork.SSID
        trustStatusLabel.text = TextsAsset.NetworkSecurity.untrusted
        if wifiNetwork.status {
            trustStatusLabel.text = TextsAsset.NetworkSecurity.trusted
        }
    }

    @objc func trustDropdownButtonTapped() {
        guard let indexPath = indexPath else { return }
        delegate?.showNetworkList(indexPath: indexPath)
    }

    func showNoNetworksAvailable() {
        trustStatusLabel.text = ""
        arrowIcon.image = nil
        nameLabel.text = TextsAsset.noNetworksAvailable
    }

    func displayForPrefferedAppearence() {
        let dark = themeManager.getIsDarkTheme()
        if !dark {
            nameLabel.textColor = UIColor.midnight
            trustStatusLabel.textColor = UIColor.midnight
            arrowIcon.image = UIImage(named: ImagesAsset.prefRightIcon)
            cellDivider.backgroundColor = UIColor.midnight
        } else {
            nameLabel.textColor = UIColor.white
            trustStatusLabel.textColor = UIColor.white
            arrowIcon.image = UIImage(named: ImagesAsset.DarkMode.prefRightIcon)
            cellDivider.backgroundColor = UIColor.white
        }
    }
}

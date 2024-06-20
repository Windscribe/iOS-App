//
//  MainViewController+Theme.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-30.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import UIKit

extension MainViewController {
    func updateLayoutForTheme(isDarkMode: Bool) {
        if let serverRefreshControl = self.serverListTableView.refreshControl as? WSRefreshControl {
            serverRefreshControl.backView.label.backgroundColor = .clear
        }

        if isDarkMode {
            cardView.backgroundColor = UIColor.lightMidnight
            cardTopView.backgroundColor = UIColor.white
            headerGradientView.layer.opacity = 1.0

            staticIPTableViewFooterView.backgroundColor = UIColor.seperatorGray
            staticIPTableViewFooterView.actionButton.setTitleColor(UIColor.darkBlack, for: .normal)
            staticIPTableViewFooterView.label.textColor = UIColor.white
            staticIPTableViewFooterView.deviceNameLabel.textColor = UIColor.white
            staticIPTableViewFooterView.iconView.image = UIImage(named: ImagesAsset.smallWhiteRightArrow)

            customConfigTableViewFooterView.backgroundColor = UIColor.seperatorGray
            customConfigTableViewFooterView.actionButton.setTitleColor(UIColor.darkBlack, for: .normal)
            customConfigTableViewFooterView.label.textColor = UIColor.white
            customConfigTableViewFooterView.iconView.image = UIImage(named: ImagesAsset.smallWhiteRightArrow)
        } else {
            cardView.backgroundColor = UIColor.white
            cardTopView.backgroundColor = UIColor.midnight
            headerGradientView.layer.opacity = 0.50

            staticIPTableViewFooterView.backgroundColor = UIColor.seperatorWhite
            staticIPTableViewFooterView.actionButton.setTitleColor(UIColor.midnight, for: .normal)
            staticIPTableViewFooterView.label.textColor = UIColor.midnight
            staticIPTableViewFooterView.deviceNameLabel.textColor = UIColor.midnight
            staticIPTableViewFooterView.iconView.image = UIImage(named: ImagesAsset.rightArrow)

            customConfigTableViewFooterView.backgroundColor = UIColor.seperatorWhite
            customConfigTableViewFooterView.actionButton.setTitleColor(UIColor.midnight, for: .normal)
            customConfigTableViewFooterView.label.textColor = UIColor.midnight
            customConfigTableViewFooterView.iconView.image = UIImage(named: ImagesAsset.rightArrow)
        }
        reloadTableViews()
    }
}

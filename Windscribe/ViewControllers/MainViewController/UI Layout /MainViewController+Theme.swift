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
        if let serverRefreshControl = serverListTableView.refreshControl as? WSRefreshControl {
            serverRefreshControl.backView.label.backgroundColor = .clear
        }

        let mainColor: UIColor = isDarkMode ? .white : .midnight
        let textcolor: UIColor = isDarkMode ? .darkBlack : .midnight
        staticIPTableViewFooterView.backgroundColor = isDarkMode ? .seperatorGray : .seperatorWhite
        staticIPTableViewFooterView.actionButton.setTitleColor(textcolor, for: .normal)
        staticIPTableViewFooterView.label.textColor = mainColor
        staticIPTableViewFooterView.deviceNameLabel.textColor = mainColor
        staticIPTableViewFooterView.iconView.setImageColor(color: mainColor)
        customConfigTableViewFooterView.backgroundColor = isDarkMode ? .seperatorGray : .seperatorWhite
        customConfigTableViewFooterView.actionButton.setTitleColor(textcolor, for: .normal)
        customConfigTableViewFooterView.label.textColor =  mainColor
        customConfigTableViewFooterView.iconView.setImageColor(color: mainColor)
        favTableView.backgroundColor = isDarkMode ? .nightBlue : .white
        staticIpTableView.backgroundColor = isDarkMode ? .nightBlue : .white
        customConfigTableView.backgroundColor = isDarkMode ? .nightBlue : .white
        serverListTableView.backgroundColor = isDarkMode ? .nightBlue : .white
        reloadTableViews()
    }
}

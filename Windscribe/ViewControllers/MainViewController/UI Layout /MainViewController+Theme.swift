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

        let backgroundColor: UIColor =  .from(.backgroundColor, isDarkMode)
        favTableView.backgroundColor = backgroundColor
        staticIpTableView.backgroundColor = backgroundColor
        customConfigTableView.backgroundColor = backgroundColor
        serverListTableView.backgroundColor = backgroundColor
        reloadTableViews()
    }
}

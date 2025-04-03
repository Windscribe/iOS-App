//
//  MainViewController+CustomConfigPicker.swift
//  Windscribe
//
//  Created by Andre Fonseca on 07/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController: CustomConfigListViewDelegate {
    func hideCustomConfigRefreshControl() {
        if customConfigTableView.subviews.contains(customConfigsTableViewRefreshControl) {
            customConfigsTableViewRefreshControl.removeFromSuperview()
        }
        customConfigTableViewFooterView.isHidden = true
    }

    func showCustomConfigRefreshControl() {
        if !customConfigTableView.subviews.contains(customConfigsTableViewRefreshControl) {
            customConfigTableView.addSubview(customConfigsTableViewRefreshControl)
        }
        customConfigTableViewFooterView.isHidden = false
    }
}

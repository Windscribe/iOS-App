//
//  MainViewController+UIScrollViewDelegate.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_: UIScrollView) {
        setHeaderViewSelector()
    }

    func disableTableViewScrolls() {
        serverListTableView.isScrollEnabled = false
        favTableView.isScrollEnabled = false
        streamingTableView.isScrollEnabled = false
        staticIpTableView.isScrollEnabled = false
        customConfigTableView.isScrollEnabled = false
    }

    func enableTableViewScrolls() {
        serverListTableView.isScrollEnabled = true
        favTableView.isScrollEnabled = true
        streamingTableView.isScrollEnabled = true
        staticIpTableView.isScrollEnabled = true
        customConfigTableView.isScrollEnabled = true
    }

    func scrollViewWillBeginDragging(_: UIScrollView) {
        disableTableViewScrolls()
    }

    func scrollViewWillEndDragging(_: UIScrollView,
                                   withVelocity _: CGPoint,
                                   targetContentOffset _: UnsafeMutablePointer<CGPoint>) {
        HapticFeedbackGenerator.shared.run(level: .medium)
        enableTableViewScrolls()
    }
}

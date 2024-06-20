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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setHeaderViewSelector()
    }

    func disableTableViewScrolls() {
        self.serverListTableView.isScrollEnabled = false
        self.favTableView.isScrollEnabled = false
        self.streamingTableView.isScrollEnabled = false
        self.staticIpTableView.isScrollEnabled = false
        self.customConfigTableView.isScrollEnabled = false
    }

    func enableTableViewScrolls() {
        self.serverListTableView.isScrollEnabled = true
        self.favTableView.isScrollEnabled = true
        self.streamingTableView.isScrollEnabled = true
        self.staticIpTableView.isScrollEnabled = true
        self.customConfigTableView.isScrollEnabled = true
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.disableTableViewScrolls()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        HapticFeedbackGenerator.shared.run(level: .medium)
       enableTableViewScrolls()
    }

}

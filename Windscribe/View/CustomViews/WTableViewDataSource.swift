//
//  WTableViewDataSource.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-20.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import ExpyTableView
import UIKit

protocol WTableViewDataSourceDelegate: AnyObject {
    func handleRefresh()
    func tableViewScrolled(toTop: Bool)
}

class WTableViewDataSource: NSObject, UITableViewDelegate {
    var canRefresh: Bool = true
    weak var scrollViewDelegate: WTableViewDataSourceDelegate?
    var beginDragging: CGFloat = 0.0

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if UIDevice.isIphone6orLess() {
            if canRefresh &&
           (scrollView.contentOffset.y < -scrollView.frame.height / 3.5) &&
            scrollView.isDecelerating &&
            beginDragging == 0.0 {
                canRefresh = false
                scrollViewDelegate?.handleRefresh()
            }

            if !canRefresh && (scrollView.contentOffset.y >= 0) {
                canRefresh = true
            }
        }
        scrollViewDelegate?.tableViewScrolled(toTop: scrollView.contentOffset.y <= 0)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginDragging = scrollView.contentOffset.y
    }
}

protocol WExpyTableViewDataSourceDelegate: AnyObject {
    func changeForSection(tableView: UITableView,
                          state: ExpyState,
                          section: Int)
}

class WExpyTableViewDataSource: WTableViewDataSource, ExpyTableViewDelegate {
    weak var expyDelegate: WExpyTableViewDataSourceDelegate?

    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
        expyDelegate?.changeForSection(tableView: tableView, state: state, section: section)
    }
}

//
//  MainViewController+StreamingListTableViewDelegate.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation

extension MainViewController: StreamingListTableViewDelegate {
    func streamingListExpandStatusChanged() {
        streamingTableView.reloadData()
    }
}

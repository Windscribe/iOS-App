//
//  MainViewController+FavNodes.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController: FavNodesListTableViewDelegate {
    func setSelectedFavNode(favNode: FavNodeModel) {
        favNodesListViewModel.setSelectedFavNode(favNode: favNode)
    }

    func hideFavNodeRefreshControl() {
        if favTableView.subviews.contains(favTableViewRefreshControl) {
            favTableViewRefreshControl.removeFromSuperview()
        }
    }

    func showFavNodeRefreshControl() {
        if !favTableView.subviews.contains(favTableViewRefreshControl) {
            favTableView.addSubview(favTableViewRefreshControl)
        }
    }
}

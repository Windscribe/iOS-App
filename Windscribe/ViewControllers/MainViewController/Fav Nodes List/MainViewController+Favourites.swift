//
//  MainViewController+Favourites.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController: FavouriteListTableViewDelegate {
    func setSelectedFavourite(favourite: GroupModel) {
        favNodesListViewModel.setSelectedFav(favourite: favourite)
    }

    func hideFavouritesRefreshControl() {
        if favTableView.subviews.contains(favTableViewRefreshControl) {
            favTableViewRefreshControl.removeFromSuperview()
        }
    }

    func showFavouritesRefreshControl() {
        if !favTableView.subviews.contains(favTableViewRefreshControl) {
            favTableView.addSubview(favTableViewRefreshControl)
        }
    }
}

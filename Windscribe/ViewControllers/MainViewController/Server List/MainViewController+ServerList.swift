//
//  MainViewController+ServerList.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController: ServerListTableViewDelegate {
    func setSelectedServerAndGroup(server: ServerModel, group: GroupModel) {
        searchLocationsView.viewModel.dismiss()
        customSoundPlaybackManager.playSound(for: .connect)
        serverListViewModel.setSelectedServerAndGroup(server: server, group: group)
    }

    func connectToBestLocation() {
        searchLocationsView.viewModel.dismiss()
        customSoundPlaybackManager.playSound(for: .connect)
        serverListViewModel.connectToBestLocation()
    }

    func reloadServerListTableView() {
        DispatchQueue.main.async { [weak self] in
            self?.serverListTableView.reloadData()
        }
    }
}

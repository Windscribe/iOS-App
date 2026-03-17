//
//  MainViewController+LocationList.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController: LocationsListTableViewDelegate {
    func setSelectedLocationAndDatacenter(location: LocationModel, datacenter: DatacenterModel) {
        searchLocationsView.viewModel.dismiss()
        serverListViewModel.setSelectedLocationAndDatacenter(location: location, datacenter: datacenter)
    }

    func connectToBestLocation() {
        searchLocationsView.viewModel.dismiss()
        serverListViewModel.connectToBestLocation()
    }

    func reloadLocationsListTableView() {
        DispatchQueue.main.async { [weak self] in
            self?.locationsListTableView.reloadData()
        }
    }
}

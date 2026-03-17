//
//  MainViewController+SearchLocationDelegate.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import UIKit

private enum MatchType {
    case groupPrefix
    case cityPrefix
    case groupContains
    case cityContains
}

extension MainViewController {
    func addSearchViews() {
        var viewModel = Assembler.resolve(SearchLocationsViewModelType.self)
        viewModel.delegate = self
        searchLocationsView = SearchLocationsView(viewModel: viewModel, locationSectionOpacity: locationSectionOpacity)
        view.addSubview(searchLocationsView)
        searchLocationsView.loadView()

        addSearchViewConstraints()
    }

    private func addSearchViewConstraints() {
        searchLocationsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchLocationsView.bottomAnchor.constraint(equalTo: listSelectionView.bottomAnchor),
            searchLocationsView.topAnchor.constraint(equalTo: view.topAnchor),
            searchLocationsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchLocationsView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func toggleSearchViews(to searchVisible: Bool) {
        connectButtonView.connectButton.isEnabled = !searchVisible
        scrollView.isScrollEnabled = !searchVisible

        if searchVisible {
            removeRefreshControls()
        } else {
            listSelectionView.viewModel.setActive()
            addRefreshControls()
            reloadServerListForSearch()
        }
    }

    func reloadServerListForSearch(reloadFinishedCompletion: (() -> Void)? = nil) {
        let results = viewModel.locationsList.value
        if results.count == 0 { return }
        loadLocationsTable(locations: results, shouldColapse: true, reloadFinishedCompletion: reloadFinishedCompletion)
    }
}

extension MainViewController: SearchCountryViewDelegate {
    func searchLocationUpdated(with text: String) {
        reloadServerListForSearch { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let locationSections = self.locationsListTableViewDataSource?.locationsSections else { return }
                var resultLocationSections = [LocationSection]()
                let locationModels = locationSections.map {$0.location!}
                let sortedModels = self.find(locationList: locationModels, keyword: text)
                resultLocationSections = sortedModels.map {LocationSection(location: $0, collapsed: text.isEmpty)}
                self.locationsListTableViewDataSource.updateServerList(with: resultLocationSections, shouldColapse: false)
                // Sync tableView with new section count before expanding/collapsing
                self.locationsListTableView.reloadData()
                for (index, locationSection) in resultLocationSections.enumerated() {
                    if locationSection.collapsed == false, !text.isEmpty {
                        self.locationsListTableView.expand(index)
                    } else {
                        self.locationsListTableView.collapse(index)
                    }
                }
                if text.isEmpty {
                    self.serverHeaderView.updadeWithSearchResult(searchCount: -1)
                } else {
                    self.serverHeaderView.updadeWithSearchResult(searchCount: resultLocationSections.count)
                }
            }
        }
    }

    private func find(locationList: [LocationModel], keyword: String) -> [LocationModel] {
        var groupNamePrefixMatches: [LocationModel] = []
        var cityPrefixMatches: [LocationModel] = []
        var groupNameContainsMatches: [LocationModel] = []
        var cityContainsMatches: [LocationModel] = []
        var serverList: [LocationModel] = locationList

        var bestLocations: [LocationModel] = []

        if let first = serverList.first {
            if first.name == Fields.Values.bestLocation {
                bestLocations =  [first]
                serverList.remove(at: 0)
            }
        }

        let lowerCaseKeyword = keyword.lowercased()

        for locationModel in serverList {
            if let (filteredGroup, matchType) = filterIfContains(locationModel: locationModel, keyword: lowerCaseKeyword) {
                switch matchType {
                case .groupPrefix:
                    groupNamePrefixMatches.append(filteredGroup)
                case .cityPrefix:
                    cityPrefixMatches.append(filteredGroup)
                case .groupContains:
                    groupNameContainsMatches.append(filteredGroup)
                case .cityContains:
                    cityContainsMatches.append(filteredGroup)
                }
            }
        }
        return bestLocations + groupNamePrefixMatches + cityPrefixMatches + groupNameContainsMatches + cityContainsMatches
    }

    /// Checks what kind of MatchType best fits group with the keyword from the search
    /// This will allow the list to be better order and give priority to the the keyword being in the server name first and then in the city name or nick name
    private func filterIfContains(locationModel: LocationModel, keyword: String) -> (LocationModel, MatchType)? {
        var datacenterList: [DatacenterModel] = []
        var bestMatch: MatchType?
        let name = locationModel.name.lowercased()
        if name.hasPrefix(keyword) {
            bestMatch = .groupPrefix
        } else if name.contains(keyword) {
            bestMatch = .groupContains
        }
        for cityGroup in locationModel.datacenters {
            let nick = cityGroup.nick.lowercased()
            let city = cityGroup.city.lowercased()
            if nick.hasPrefix(keyword) || city.hasPrefix(keyword) {
                bestMatch = bestMatch ?? .cityPrefix
                datacenterList.append(cityGroup)
            } else if nick.contains(keyword) || city.contains(keyword) {
                if bestMatch == nil {
                    bestMatch = .cityContains
                }
                datacenterList.append(cityGroup)
            }
        }
        if let match = bestMatch, match == .groupPrefix || match == .groupContains {
            datacenterList = locationModel.datacenters
        }
        if let match = bestMatch {
            let newLocation = locationModel.copyModelWith(datacenters: datacenterList)
            return (newLocation, match)
        }
        return nil
    }

    func showSearchLocation() {
        logger.logD("MainViewController", "User tapped to search locations.")
        clearScrollHappened()
        lastSelectedHeaderViewTab = selectedHeaderViewTab ?? .all
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        toggleSearchViews(to: true)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.expandedSections = self.locationsListTableView.expandedSections
            self.locationsListTableView.collapseExpandedSections()

            self.listSelectionViewTopConstraint.isActive = true
            self.listSelectionViewBottomConstraint.isActive = false
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
                self.searchLocationsView.setSearchSelected(isSelected: true)
            }
            locationsListTableViewDataSource.setBestLocationVisibility(to: false)
        }
    }

    func dismissSearchLocation() {
        if let lastSelectedHeaderViewTab = lastSelectedHeaderViewTab {
            cardHeaderWasSelected(with: lastSelectedHeaderViewTab)
        }
        toggleSearchViews(to: false)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.reloadServerListOrder()

            self.listSelectionViewTopConstraint.isActive = false
            self.listSelectionViewBottomConstraint.isActive = true
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
                self.searchLocationsView.setSearchSelected(isSelected: false)
            }
            locationsListTableViewDataSource.setBestLocationVisibility(to: true)
        }
    }
}

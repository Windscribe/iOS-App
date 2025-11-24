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
        searchLocationsView = SearchLocationsView(viewModel: viewModel, serverSectionOpacity: serverSectionOpacity)
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
        guard let results = try? viewModel.serverList.value() else { return }
        if results.count == 0 { return }
        loadServerTable(servers: results, shouldColapse: true, reloadFinishedCompletion: reloadFinishedCompletion)
    }
}

extension MainViewController: SearchCountryViewDelegate {
    func searchLocationUpdated(with text: String) {
        reloadServerListForSearch { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let serverSections = self.serverListTableViewDataSource?.serverSections else { return }
                var resultServerSections = [ServerSection]()
                let serverModels = serverSections.map {$0.server!}
                let sortedModels = self.find(groupList: serverModels, keyword: text)
                resultServerSections = sortedModels.map {ServerSection(server: $0, collapsed: text.isEmpty)}
                self.serverListTableViewDataSource?.serverSections = resultServerSections
                self.serverListTableView.reloadData()
                for (index, serverSection) in resultServerSections.enumerated() {
                    if serverSection.collapsed == false, !text.isEmpty {
                        self.serverListTableView.expand(index)
                    } else {
                        self.serverListTableView.collapse(index)
                    }
                }
                if text.isEmpty {
                    self.serverHeaderView.updadeWithSearchResult(searchCount: -1)
                } else {
                    self.serverHeaderView.updadeWithSearchResult(searchCount: resultServerSections.count)
                }
            }
        }
    }

    private func find(groupList: [ServerModel], keyword: String) -> [ServerModel] {
        var groupNamePrefixMatches: [ServerModel] = []
        var cityPrefixMatches: [ServerModel] = []
        var groupNameContainsMatches: [ServerModel] = []
        var cityContainsMatches: [ServerModel] = []
        var serverList: [ServerModel] = groupList

        var bestLocations: [ServerModel] = []

        if let first = serverList.first {
            if first.name == Fields.Values.bestLocation {
                bestLocations =  [first]
                serverList.remove(at: 0)
            }
        }

        let lowerCaseKeyword = keyword.lowercased()

        for serverModel in serverList {
            if let (filteredGroup, matchType) = filterIfContains(serverModel: serverModel, keyword: lowerCaseKeyword) {
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
    private func filterIfContains(serverModel: ServerModel, keyword: String) -> (ServerModel, MatchType)? {
        var cities: [GroupModel] = []
        var bestMatch: MatchType?
        let name = serverModel.name.lowercased()
        if name.hasPrefix(keyword) {
            bestMatch = .groupPrefix
        } else if name.contains(keyword) {
            bestMatch = .groupContains
        }
        for cityGroup in serverModel.groups {
            let nick = cityGroup.nick.lowercased()
            let city = cityGroup.city.lowercased()
            if nick.hasPrefix(keyword) || city.hasPrefix(keyword) {
                bestMatch = bestMatch ?? .cityPrefix
                cities.append(cityGroup)
            } else if nick.contains(keyword) || city.contains(keyword) {
                if bestMatch == nil {
                    bestMatch = .cityContains
                }
                cities.append(cityGroup)
            }
        }
        if let match = bestMatch, match == .groupPrefix || match == .groupContains {
            cities = serverModel.groups
        }
        if let match = bestMatch {
            let newServer = serverModel.copyModelWith(newGroups: cities)
            return (newServer, match)
        }
        return nil
    }

    func showSearchLocation() {
        logger.logD("MainViewController", "User tapped to search locations.")
        clearScrollHappened()
        lastSelectedHeaderViewTab = selectedHeaderViewTab ?? .all
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        toggleSearchViews(to: true)
        serverListTableViewDataSource?.bestLocation = nil
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.expandedSections = self.serverListTableView.expandedSections
            self.serverListTableView.collapseExpandedSections()

            self.listSelectionViewTopConstraint.isActive = true
            self.listSelectionViewBottomConstraint.isActive = false
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
                self.searchLocationsView.setSearchSelected(isSelected: true)
            }
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
        }
    }
}

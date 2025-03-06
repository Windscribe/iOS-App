//
//  MainViewController+SearchLocationDelegate.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

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
            searchLocationsView.centerYAnchor.constraint(equalTo: cardTopView.centerYAnchor),
            searchLocationsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchLocationsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchLocationsView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func toggleSearchViews(to searchVisible: Bool) {
        connectButton.isEnabled = !searchVisible
        scrollView.isScrollEnabled = !searchVisible

        if searchVisible {
            removeRefreshControls()
        } else {
            cardHeaderContainerView.viewModel.setActive()
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
            }
        }
    }

    private func find(groupList: [ServerModel], keyword: String) -> [ServerModel] {
        var groupNamePrefixMatches: [ServerModel] = []
        var cityPrefixMatches: [ServerModel] = []
        var groupNameContainsMatches: [ServerModel] = []
        var cityContainsMatches: [ServerModel] = []

        let lowerCaseKeyword = keyword.lowercased()

        for group in groupList {
            if let (filteredGroup, matchType) = filterIfContains(group: group, keyword: lowerCaseKeyword) {
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
        return groupNamePrefixMatches + cityPrefixMatches + groupNameContainsMatches + cityContainsMatches
    }

    private func filterIfContains(group: ServerModel, keyword: String) -> (ServerModel, MatchType)? {
        var cities: [GroupModel] = []
        var bestMatch: MatchType?
        if let name = group.name?.lowercased() {
            if name.hasPrefix(keyword) {
                bestMatch = .groupPrefix
            } else if name.contains(keyword) {
                bestMatch = .groupContains
            }
        }
        if let items = group.groups {
            for cityGroup in items {
                if let nick = cityGroup.nick?.lowercased(), let city = cityGroup.city?.lowercased() {
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
            }
        }
        if let match = bestMatch, match == .groupPrefix || match == .groupContains {
            cities = group.groups ?? []
        }
        if let match = bestMatch {
            let newServer = ServerModel(
                id: group.id,
                name: group.name,
                countryCode: group.countryCode,
                status: group.status,
                premiumOnly: group.premiumOnly,
                dnsHostname: group.dnsHostname,
                groups: cities,
                locType: group.locType,
                p2p: group.p2p
            )
            return (newServer, match)
        }
        return nil
    }

    func showSearchLocation() {
        logger.logD(self, "User tapped to search locations.")
        clearScrollHappened()
        hideAutoSecureViews()
        lastSelectedHeaderViewTab = selectedHeaderViewTab
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        toggleSearchViews(to: true)
        serverListTableViewDataSource?.bestLocation = nil
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
                var fullTopSpace = -(self?.trustedNetworkValueLabel.frame.maxY ?? 0) + 20
                if UIScreen.hasTopNotch {
                    fullTopSpace = -(self?.trustedNetworkValueLabel.frame.maxY ?? 0) + 35
                }
                self?.cardViewTopConstraint.constant = fullTopSpace
                self?.cardHeaderContainerView.headerSelectorView.isHidden = true
                self?.view.layoutIfNeeded()
            }, completion: { _ in
                self?.expandedSections = self?.serverListTableView.expandedSections
                self?.serverListTableView.collapseExpandedSections()
            })
        }
    }

    func dismissSearchLocation() {
        if let lastSelectedHeaderViewTab = lastSelectedHeaderViewTab {
            cardHeaderWasSelected(with: lastSelectedHeaderViewTab)
        }
        toggleSearchViews(to: false)
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
                self?.cardViewTopConstraint.constant = 16
                self?.cardHeaderContainerView.headerSelectorView.isHidden = false
                self?.view.layoutIfNeeded()
            }, completion: { _ in
                self?.reloadServerListOrder()
            })
        }
    }
}

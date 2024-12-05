//
//  MainViewController+SearchLocationDelegate.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

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
            searchLocationsView.heightAnchor.constraint(equalToConstant: 24),
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
                guard let self = self,
                      let serverSections = self.serverListTableViewDataSource?.serverSections
                else { return }
                if text.isEmpty {
                    for (index, _) in serverSections.enumerated() {
                        self.serverListTableView.collapse(index)
                    }
                    return
                }
                var resultServerSections = [ServerSection]()
                let serverModels = serverSections.map {$0.server!}
                let sortedModels = self.find(groupList: serverModels, keyword: text)
                resultServerSections = sortedModels.map {ServerSection(server: $0, collapsed: false)}
                self.serverListTableViewDataSource?.serverSections = resultServerSections
                self.serverListTableView.reloadData()
                for (index, serverSection) in resultServerSections.enumerated() {
                    if serverSection.collapsed == false {
                        self.serverListTableView.expand(index)
                    } else {
                        self.serverListTableView.collapse(index)
                    }
                }
            }
        }
    }

    private func find(groupList: [ServerModel], keyword: String) -> [ServerModel] {
        // Filter servers containing the keyword
        var updatedList: [ServerModel] = []
        for group in groupList {
            if let filteredGroup = filterIfContains(group: group, keyword: keyword) {
                updatedList.append(filteredGroup)
            }
        }
        return updatedList
    }

    private func filterIfContains(group: ServerModel, keyword: String) -> ServerModel? {
        var cities: [GroupModel] = []
        // Filter server by keyword
        if let items = group.groups {
            for group in items {
                if let nick = group.nick?.lowercased(), let city = group.city?.lowercased() {
                    let lowerCaseKeyword = keyword.lowercased()
                    if nick.contains(lowerCaseKeyword) ||
                        city.contains(lowerCaseKeyword) {
                        cities.append(group)
                    }
                }
            }
        }

        // Return new server if cities match or title matches
        if !cities.isEmpty {
            return ServerModel(id: group.id, name: group.name, countryCode: group.countryCode, status: group.status, premiumOnly: group.premiumOnly, dnsHostname: group.dnsHostname, groups: cities, locType: group.locType, p2p: group.p2p)
        }

        if let name = group.name {
            if name.lowercased().contains(keyword.lowercased()) {
                return group
            }
        }
        return nil
    }

    private func filterIfStartsWith(group: ServerModel, keyword: String) -> Bool {
        let lowerCaseKeyword = keyword.lowercased()

        // Check if server title starts with keyword

        if let name = group.name {
            if name.lowercased().hasPrefix(lowerCaseKeyword) {
                return true
            }
        }

        // Check if any group starts with keyword

        if let items = group.groups {
            for group in items {
                if let nick = group.nick?.lowercased(), let city = group.city?.lowercased() {
                    let lowerCaseKeyword = keyword.lowercased()
                    if nick.lowercased().hasPrefix(lowerCaseKeyword) ||
                        city.lowercased().hasPrefix(lowerCaseKeyword) {
                        return true
                    }
                }
            }
        }
        return false
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

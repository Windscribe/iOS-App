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

        self.addSearchViewConstraints()
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
    func reloadServerListForSearch() {
        guard let results = try? viewModel.serverList.value() else { return }
        if results.count == 0 { return }
        let serverModels = results.compactMap({ $0.getServerModel() })
        let serverSections: [ServerSection] = serverModels.map({ ServerSection(server: $0, collapsed: true) })
        let serverSectionsOrdered = self.sortServerListUsingUserPreferences(serverSections: serverSections)
        self.serverListTableViewDataSource?.serverSections = serverSectionsOrdered
        self.serverListTableViewDataSource?.bestLocation = nil
        self.serverListTableView.reloadData()
    }
}

extension MainViewController: SearchCountryViewDelegate {
    func searchLocationUpdated(with text: String) {
        reloadServerListForSearch()
        guard let serverSections = serverListTableViewDataSource?.serverSections else { return }
        if text.isEmpty {
            for (index, _) in serverSections.enumerated() {
                serverListTableView.collapse(index)
            }
            return
        }

        var resultServerSections = [ServerSection]()
        for serverSection in serverSections {
            let lowercasedText = text.lowercased()
            guard let server = serverSection.server, let serverId = server.id, let serverName = serverSection.server?.name, let serverNameLowerCased = serverSection.server?.name?.lowercased(), let serverStatus = server.status, let groups = serverSection.server?.groups, let serverCountryCode = server.countryCode, let serverPremiumOnly = server.premiumOnly, let serverDnsHostname = server.dnsHostname, let serverLocType = server.locType, let p2p = server.p2p else { continue }
            if serverNameLowerCased.contains(lowercasedText) {
                resultServerSections.append(ServerSection(server: server, collapsed: true))
            }
            var resultGroups = [GroupModel]()
            if lowercasedText == " " {
                resultGroups.append(contentsOf: groups)
            } else {
                for group in groups {
                    guard let city = group.city?.lowercased(), let nick = group.nick?.lowercased() else { continue }
                    lowercasedText.splitToArray(separator: " ").forEach { s in
                        if city.range(of: s) != nil || nick.range(of: s) != nil {
                            let added = resultGroups.contains { $0.id == group.id }
                            if !added {
                                resultGroups.append(group)
                            }
                        }
                    }
                }
            }
            let serverModel = ServerModel(id: serverId, name: serverName, countryCode: serverCountryCode, status: serverStatus, premiumOnly: serverPremiumOnly, dnsHostname: serverDnsHostname, groups: resultGroups, locType: serverLocType, p2p: p2p)
            if !resultServerSections.contains(where: { $0.server?.name == serverSection.server?.name }) && serverModel.groups?.count != 0 {
                resultServerSections.append(ServerSection(server: serverModel, collapsed: false))
            }
        }
        serverListTableViewDataSource?.serverSections = resultServerSections
        serverListTableView.reloadData()
        for (index, serverSection) in resultServerSections.enumerated() {
            if serverSection.collapsed == false {
                serverListTableView.expand(index)
            } else {
                serverListTableView.collapse(index)
            }
        }
    }

    func showSearchLocation() {
        logger.logD(self, "User tapped to search locations.")
        self.clearScrollHappened()
        self.hideAutoSecureViews()
        self.lastSelectedHeaderViewTab = self.selectedHeaderViewTab
        self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
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

//
//  ServerListTableViewDataSource+Delegate.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import ExpyTableView
import RealmSwift
import RxSwift
import UIKit

protocol ServerListTableViewDelegate: AnyObject {
    func setSelectedServerAndGroup(server: ServerModel, group: GroupModel)
    func reloadServerListTableView()
    func connectToBestLocation()
    func handleRefresh()
    func tableViewScrolled(toTop: Bool)
}

class ServerListTableViewDataSource: WExpyTableViewDataSource,
    ExpyTableViewDataSource,
    WExpyTableViewDataSourceDelegate,
    WTableViewDataSourceDelegate {
    var hapticFeedbackCounter = 0
    let disposeBag = DisposeBag()
    var bestLocation: BestLocationModel? {
        didSet {
            if bestLocation != nil,
               serverSections.first?.server?.name != Fields.Values.bestLocation,
               let groupId = bestLocation?.groupId,
               let serverModel = viewModel.getServerModel(from: groupId) {
                let bestLocationServer = ServerModel(name: Fields.Values.bestLocation, serverModel: serverModel)
                serverSections.insert(ServerSection(server: bestLocationServer, collapsed: true), at: 0)
            }
            delegate?.reloadServerListTableView()
        }
    }

    var serverSections: [ServerSection] = []
    weak var delegate: ServerListTableViewDelegate?
    var favList: [GroupModel]? {
        didSet {
            delegate?.reloadServerListTableView()
        }
    }

    var favNodesNotificationToken: NotificationToken?
    var scrollHappened = false
    var viewModel: MainViewModelType!
    init(serverSections: [ServerSection], viewModel: MainViewModelType, shouldColapse: Bool = false) {
        super.init()
        self.scrollViewDelegate = self
        self.expyDelegate = self
        self.viewModel = viewModel
        self.serverSections = serverSections.map({
            if shouldColapse, let server = $0.server {
                return ServerSection(server: server, collapsed: true)
            }
            return $0
        })

        viewModel.favouriteList.observe(on: MainScheduler.asyncInstance).subscribe(onNext: {
            self.favList = $0
        }).disposed(by: disposeBag)
    }

    func numberOfSections(in _: UITableView) -> Int {
        if bestLocation != nil,
           serverSections.first?.server?.name != Fields.Values.bestLocation,
           let groupId = bestLocation?.groupId,
           let serverModel = viewModel.getServerModel(from: groupId) {
            let bestLocationServer = ServerModel(name: Fields.Values.bestLocation, serverModel: serverModel)
            serverSections.insert(ServerSection(server: bestLocationServer, collapsed: true), at: 0)
        }
        return serverSections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && bestLocation != nil { return 1 }
        if serverSections.indices.contains(section) {
            guard let count = serverSections[section].server?.groups.count else { return 0 }
            return count + 1
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifiers.nodeCellReuseIdentifier, for: indexPath) as? NodeTableViewCell
        ?? NodeTableViewCell(style: .default, reuseIdentifier: ReuseIdentifiers.nodeCellReuseIdentifier)
        if (serverSections.count > indexPath.section) && ((serverSections[indexPath.section].server?.groups.count ?? 0) > indexPath.row - 1) {
            let group = serverSections[indexPath.section].server?.groups[indexPath.row - 1]
            cell.bindViews(isDarkMode: viewModel.isDarkMode)
            cell.nodeCellViewModel = NodeTableViewCellModel(displayingGroup: group)
        }
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && bestLocation != nil {
            delegate?.connectToBestLocation()
        }
        if indexPath.row == 0 { return }
        guard let server = serverSections[indexPath.section].server else { return }
        let group = server.groups[indexPath.row - 1]
        delegate?.setSelectedServerAndGroup(server: server, group: group)
    }

    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        if section == 0 && bestLocation != nil {
            let bestLocationCell = tableView.dequeueReusableCell(
                withIdentifier: ReuseIdentifiers.bestLocationCellReuseIdentifier)! as? BestLocationCell
                ?? BestLocationCell(
                    style: .default,
                    reuseIdentifier: ReuseIdentifiers.bestLocationCellReuseIdentifier)
            bestLocationCell.bestCellViewModel = BestLocationCellModel()
            bestLocationCell.updateBestLocation(bestLocation)
            bestLocationCell.bindViews(isDarkMode: viewModel.isDarkMode)
            return bestLocationCell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ReuseIdentifiers.serverSectionCellReuseIdentifier)! as? ServerSectionCell
                ?? ServerSectionCell(
                    style: .default,
                    reuseIdentifier: ReuseIdentifiers.serverSectionCellReuseIdentifier)
            cell.serverCellViewModel = ServerSectionCellModel()
            if let expanded = tableView.expandedSections[section] {
                serverSections[section].collapsed = !expanded
            }
            cell.bindViews(isDarkMode: viewModel.isDarkMode)
            if serverSections.count > 0 {
                cell.setCollapsed(collapsed: serverSections[section].collapsed)
                cell.updateServerModel(serverSections[section].server)
            }
            return cell
        }
    }

    func tableView(_: UITableView,  heightForRowAt _: IndexPath) -> CGFloat {
        return 48
    }

    func changeForSection(tableView: UITableView, state: ExpyState, section: Int) {
        guard let cell = tableView.cellForRow(at: IndexPath(item: 0, section: section)) as? ServerSectionCell else { return }
        switch state {
        case .willExpand:
            serverSections[section].collapsed = false
            cell.expand()
        case .willCollapse:
            serverSections[section].collapsed = true
            cell.collapse()
        default:
            return
        }
    }

    func handleRefresh() {
        delegate?.handleRefresh()
    }

    func tableViewScrolled(toTop: Bool) {
        delegate?.tableViewScrolled(toTop: toTop)
    }

    override func scrollViewWillBeginDragging(_: UIScrollView) {
        scrollHappened = true
    }

    func tableView(_: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 && scrollHappened {
            HapticFeedbackGenerator.shared.run(level: .light)
        }
    }

    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
        true
    }
}

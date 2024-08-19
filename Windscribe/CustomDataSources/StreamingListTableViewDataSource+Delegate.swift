//
//  StreamingTableViewDataSource+Delegate.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//
import UIKit
import RealmSwift
import ExpyTableView
import RxSwift

protocol StreamingListTableViewDelegate: AnyObject {
    func setSelectedServerAndGroup(server: ServerModel,
                                   group: GroupModel)
    func streamingListExpandStatusChanged()
    func handleRefresh()
    func tableViewScrolled(toTop: Bool)
}

class StreamingListTableViewDataSource: WExpyTableViewDataSource, ExpyTableViewDataSource, WExpyTableViewDataSourceDelegate, WTableViewDataSourceDelegate {

    var streamingSections: [ServerSection] = []
    var favNodes: [FavNode]? {
        didSet {
            self.delegate?.streamingListExpandStatusChanged()
        }
    }

    let disposeBag = DisposeBag()
    weak var delegate: StreamingListTableViewDelegate?
    var favNodesNotificationToken: NotificationToken?
    var scrollHappened = false
    var viewModel: MainViewModelType

    init(streamingSections: [ServerSection], viewModel: MainViewModelType) {
        self.viewModel = viewModel
        super.init()
        self.scrollViewDelegate = self
        self.expyDelegate = self
        self.streamingSections = streamingSections
        viewModel.favNode.bind(onNext: { favNodes in
            self.favNodes = favNodes
        }).disposed(by: disposeBag)

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return streamingSections.count
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        guard let count = streamingSections[section].server?.groups?.count else { return 0 }
        return count + 1
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: nodeCellReuseIdentifier, for: indexPath) as? NodeTableViewCell ?? NodeTableViewCell(style: .default, reuseIdentifier: nodeCellReuseIdentifier)
        let group = streamingSections[indexPath.section].server?.groups?[indexPath.row-1]
        if let groupId = group?.id {
            cell.favourited = favNodes?.map({ $0.groupId }).contains("\(groupId)") ?? false
        }
        cell.bindViews(isDarkMode: viewModel.isDarkMode)
        cell.displayingGroup = group
        cell.displayingNodeServer = streamingSections[indexPath.section].server
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 { return }
        guard let server = streamingSections[indexPath.section].server, let group = server.groups?[indexPath.row-1] else { return }
        self.delegate?.setSelectedServerAndGroup(server: server, group: group)
    }

    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: serverSectionCellReuseIdentifier)! as? ServerSectionCell ?? ServerSectionCell(style: .default, reuseIdentifier: serverSectionCellReuseIdentifier)
        if let expanded = tableView.expandedSections[section] {
            streamingSections[section].collapsed = !expanded
        }
        cell.bindViews(isDarkMode: viewModel.isDarkMode)
        if streamingSections.count > section {
            cell.setCollapsed(collapsed: streamingSections[section].collapsed)
            cell.displayingServer = streamingSections[section].server
        }
        return cell
    }

    func changeForSection(tableView: UITableView, state: ExpyState, section: Int) {
        guard let cell = tableView.cellForRow(at: IndexPath(item: 0, section: section)) as? ServerSectionCell else { return }
       switch state {
       case .willExpand:
           streamingSections[section].collapsed = false
           cell.expand()
       case .willCollapse:
           streamingSections[section].collapsed = true
           cell.collapse()
       default:
           return
       }
    }

    func handleRefresh() {
        self.delegate?.handleRefresh()
    }

    func tableViewScrolled(toTop: Bool) {
        self.delegate?.tableViewScrolled(toTop: toTop)
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollHappened = true
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 && scrollHappened {
            HapticFeedbackGenerator.shared.run(level: .light)
        }
    }
}

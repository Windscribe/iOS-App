//
//  FavNodesListTableViewDataSource+Delegate.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

protocol FavNodesListTableViewDelegate: AnyObject {
    func setSelectedFavNode(favNode: FavNodeModel)
    func hideFavNodeRefreshControl()
    func showFavNodeRefreshControl()
    func handleRefresh()
    func tableViewScrolled(toTop: Bool)
}

class FavNodesListTableViewDataSource: WTableViewDataSource, UITableViewDataSource, WTableViewDataSourceDelegate {
    var favNodes: [FavNodeModel]?
    weak var delegate: FavNodesListTableViewDelegate?
    var scrollHappened = false
    var viewModel: MainViewModelType
    lazy var languageManager = Assembler.resolve(LanguageManagerV2.self)
    let disposeBag = DisposeBag()

    init(favNodes: [FavNodeModel]?, viewModel: MainViewModelType) {
        self.viewModel = viewModel
        super.init()
        scrollViewDelegate = self
        self.favNodes = favNodes
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let count = favNodes?.count else { return 0 }
        if count == 0 {
            delegate?.hideFavNodeRefreshControl()
            showEmptyView(tableView: tableView)
            tableView.tableHeaderView?.isHidden = true
        } else {
            delegate?.showFavNodeRefreshControl()
            tableView.backgroundView = nil
            tableView.tableHeaderView?.isHidden = false
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifiers.favNodeCellReuseIdentifier, for: indexPath) as? FavNodeTableViewCell
            ?? FavNodeTableViewCell(
                style: .default,
                reuseIdentifier: ReuseIdentifiers.favNodeCellReuseIdentifier)
        let node = favNodes?[indexPath.row]
        cell.bindViews(isDarkMode: viewModel.isDarkMode)
        cell.favCellViewModel = FavNodeCellModel(displayingFavNode: node)
        return cell
    }

    func tableView(_: UITableView,  heightForRowAt _: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let favNode = favNodes?[indexPath.row] else { return }
        delegate?.setSelectedFavNode(favNode: favNode)
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 0
    }

    func showEmptyView(tableView: UITableView) {
        let view = ListEmptyView(type: .favNodes, isDarkMode: viewModel.isDarkMode)
        tableView.backgroundView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // view
            view.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            view.heightAnchor.constraint(equalTo: tableView.heightAnchor),
            view.widthAnchor.constraint(equalTo: tableView.widthAnchor)
        ])
        view.updateLayout()
        tableView.backgroundView = view
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
}

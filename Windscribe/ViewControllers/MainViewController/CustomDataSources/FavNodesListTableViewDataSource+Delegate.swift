//
//  FavouriteListTableViewDataSource+Delegate.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

protocol FavouriteListTableViewDelegate: AnyObject {
    func setSelectedFavourite(favourite: GroupModel)
    func hideFavouritesRefreshControl()
    func showFavouritesRefreshControl()
    func handleRefresh()
    func tableViewScrolled(toTop: Bool)
}

class FavouriteListTableViewDataSource: WSTableViewDataSource, UITableViewDataSource, WTableViewDataSourceDelegate {
    var favList: [GroupModel]?
    weak var delegate: FavouriteListTableViewDelegate?
    var scrollHappened = false
    var viewModel: MainViewModelType
    lazy var languageManager = Assembler.resolve(LanguageManager.self)
    let disposeBag = DisposeBag()

    init(favList: [GroupModel]?, viewModel: MainViewModelType) {
        self.viewModel = viewModel
        super.init()
        scrollViewDelegate = self
        self.favList = favList
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let count = favList?.count else { return 0 }
        if count == 0 {
            delegate?.hideFavouritesRefreshControl()
            showEmptyView(tableView: tableView)
            tableView.tableHeaderView?.isHidden = true
        } else {
            delegate?.showFavouritesRefreshControl()
            tableView.backgroundView = nil
            tableView.tableHeaderView?.isHidden = false
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifiers.favNodeCellReuseIdentifier, for: indexPath) as? NodeTableViewCell
        ?? NodeTableViewCell(
                style: .default,
                reuseIdentifier: ReuseIdentifiers.favNodeCellReuseIdentifier)
        let favourite = favList?[indexPath.row]
        cell.bindViews(isDarkMode: viewModel.isDarkMode)
        cell.nodeCellViewModel = NodeTableViewCellModel(displayingGroup: favourite, isFavorite: true)
        return cell
    }

    func tableView(_: UITableView,  heightForRowAt _: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let favourite = favList?[indexPath.row] else { return }
        delegate?.setSelectedFavourite(favourite: favourite)
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

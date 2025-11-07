//
//  CustomConfigListTableViewDataSource.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-02.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Combine
import RxSwift
import Swinject
import SwipeCellKit
import UIKit

protocol CustomConfigListModelDelegate: AddCustomConfigDelegate {
    func setSelectedCustomConfig(customConfig: CustomConfigModel)
    func showRemoveAlertForCustomConfig(id: String, protocolType: String)
    func showEditCustomConfig(customConfig: CustomConfigModel)
}

protocol CustomConfigListViewDelegate: WTableViewDataSourceDelegate, AnyObject {
    func hideCustomConfigRefreshControl()
    func showCustomConfigRefreshControl()
}

class CustomConfigListTableViewDataSource: WSTableViewDataSource, UITableViewDataSource, WTableViewDataSourceDelegate, SwipeTableViewCellDelegate {
    var customConfigs: [CustomConfigModel]?
    weak var logicDelegate: CustomConfigListModelDelegate?
    weak var uiDelegate: CustomConfigListViewDelegate?
    var scrollHappened = false
    var viewModel: MainViewModelType
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    init(customConfigs: [CustomConfigModel]?, viewModel: MainViewModelType) {
        self.viewModel = viewModel
        super.init()
        scrollViewDelegate = self
        self.customConfigs = customConfigs
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let count = customConfigs?.count else { return 0 }
        if count == 0 {
            uiDelegate?.hideCustomConfigRefreshControl()
            showEmptyView(tableView: tableView)
            tableView.tableHeaderView?.isHidden = true
        } else {
            uiDelegate?.showCustomConfigRefreshControl()
            tableView.backgroundView = nil
            tableView.tableHeaderView?.isHidden = false
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifiers.customConfigCellReuseIdentifier, for: indexPath) as? CustomConfigCell
            ?? CustomConfigCell(
                style: .default,
                reuseIdentifier: ReuseIdentifiers.customConfigCellReuseIdentifier)
        cell.bindViews(isDarkMode: viewModel.isDarkMode)
        cell.delegate = self
        cell.customConfigCellViewModel = CustomConfigCellModel(displayingCustomConfig: customConfigs?[indexPath.row])
        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let customConfig = customConfigs?[indexPath.row] else { return }
        logicDelegate?.setSelectedCustomConfig(customConfig: customConfig)
    }

    func showEmptyView(tableView: UITableView) {
        let view = ListEmptyView(type: .customConfig,isDarkMode: viewModel.isDarkMode)
        view.addAction = { [weak self] in
            self?.logicDelegate?.addCustomConfig()
        }
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
    }

    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        return true
    }

    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        guard let customConfig = customConfigs?[indexPath.row], let fileId = customConfig.id, let protocolType = customConfig.protocolType else { return nil }

        let deleteAction = SwipeAction(style: .destructive, title: nil) { _, _ in
            self.logicDelegate?.showRemoveAlertForCustomConfig(id: fileId, protocolType: protocolType)
        }
        let editAction = SwipeAction(style: .destructive, title: nil) { _, _ in
            self.logicDelegate?.showEditCustomConfig(customConfig: customConfig)
        }

        // Get dark mode value synchronously
        let isDark = viewModel.isDarkMode.value
        if !isDark {
            deleteAction.backgroundColor = UIColor.seperatorWhite
            deleteAction.image = UIImage(named: ImagesAsset.delete)
            editAction.backgroundColor = UIColor.seperatorWhite
            editAction.image = UIImage(named: ImagesAsset.edit)
        } else {
            deleteAction.backgroundColor = UIColor.seperatorGray
            deleteAction.image = UIImage(named: ImagesAsset.DarkMode.delete)
            editAction.backgroundColor = UIColor.seperatorGray
            editAction.image = UIImage(named: ImagesAsset.DarkMode.edit)
        }

        if customConfig.authRequired ?? false {
            return [deleteAction, editAction]
        }
        return [deleteAction]
    }

    func handleRefresh() {
        uiDelegate?.handleRefresh()
    }

    func tableViewScrolled(toTop: Bool) {
        uiDelegate?.tableViewScrolled(toTop: toTop)
    }

    override func scrollViewWillBeginDragging(_: UIScrollView) {
        scrollHappened = true
    }

    func tableView(_: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 && scrollHappened {
            viewModel.runHapticFeedback(level: .light)
        }
    }
}

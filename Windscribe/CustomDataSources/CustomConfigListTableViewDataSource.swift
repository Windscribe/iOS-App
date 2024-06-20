//
//  CustomConfigListTableViewDataSource.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-02.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import SwipeCellKit
import Swinject
import RxSwift

protocol CustomConfigListModelDelegate: AddCustomConfigDelegate {
    func setSelectedCustomConfig(customConfig: CustomConfigModel)
    func showRemoveAlertForCustomConfig(id: String, protocolType: String)
    func showEditCustomConfig(customConfig: CustomConfigModel)
}

protocol CustomConfigListViewDelegate: WTableViewDataSourceDelegate, AnyObject {
    func hideCustomConfigRefreshControl()
    func showCustomConfigRefreshControl()
}

class CustomConfigListTableViewDataSource: WTableViewDataSource,
                                           UITableViewDataSource,
                                           WTableViewDataSourceDelegate,
                                           SwipeTableViewCellDelegate {

    var customConfigs: [CustomConfigModel]?
    weak var logicDelegate: CustomConfigListModelDelegate?
    weak var uiDelegate: CustomConfigListViewDelegate?
    var scrollHappened = false
    var viewModel: MainViewModelType
    let disposeBag = DisposeBag()

    init(customConfigs: [CustomConfigModel]?, viewModel: MainViewModelType) {
        self.viewModel = viewModel
        super.init()
        self.scrollViewDelegate = self
        self.customConfigs = customConfigs
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        guard let count = customConfigs?.count else { return 0; }
        if count == 0 {
            self.uiDelegate?.hideCustomConfigRefreshControl()
            showEmptyView(tableView: tableView)
        } else {
            self.uiDelegate?.showCustomConfigRefreshControl()
            tableView.backgroundView = nil
        }
        return count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: customConfigCellReuseIdentifier, for: indexPath) as? CustomConfigTableViewCell ?? CustomConfigTableViewCell(style: .default, reuseIdentifier: customConfigCellReuseIdentifier)
        cell.bindViews(isDarkMode: viewModel.isDarkMode)
        cell.delegate = self
        let customConfig = customConfigs?[indexPath.row]
        cell.displayingCustomConfig = customConfig
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        guard let customConfig = customConfigs?[indexPath.row] else { return }
        self.logicDelegate?.setSelectedCustomConfig(customConfig: customConfig)
    }

    func showEmptyView(tableView: UITableView) {
        let view = CustomConfigEmptyView(frame: tableView.bounds, isDarkMode: viewModel.isDarkMode)
        view.addCustomConfigAction = { [weak self] in
            self?.logicDelegate?.addCustomConfig()
        }
        tableView.backgroundView = view
    }

    func tableView(_ tableView: UITableView,
                   canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        guard let customConfig = self.customConfigs?[indexPath.row], let fileId = customConfig.id, let protocolType = customConfig.protocolType else { return nil}

        let deleteAction = SwipeAction(style: .destructive, title: nil) { _, _ in
            self.logicDelegate?.showRemoveAlertForCustomConfig(id: fileId, protocolType: protocolType)
        }
        let editAction = SwipeAction(style: .destructive, title: nil) { _, _ in
            self.logicDelegate?.showEditCustomConfig(customConfig: customConfig)
        }
        viewModel.isDarkMode.subscribe(onNext: { dark in
            if !dark {
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
        }).disposed(by: disposeBag)

        if customConfig.authRequired ?? false {
            return [deleteAction, editAction]
        }
        return [deleteAction]
    }

    func handleRefresh() {
        self.uiDelegate?.handleRefresh()
    }

    func tableViewScrolled(toTop: Bool) {
        self.uiDelegate?.tableViewScrolled(toTop: toTop)
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

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
    func reloadCustomConfigListTableView()
}

protocol CustomConfigListTableViewDataSource: WSTableViewDataSource,
                                          UITableViewDataSource,
                                          WTableViewDataSourceDelegate,
                                              SwipeTableViewCellDelegate {
    var logicDelegate: CustomConfigListModelDelegate? { get set }
    var uiDelegate: CustomConfigListViewDelegate? { get set }
    var scrollHappened: Bool { get set }
    var customConfigs: [CustomConfigModel] { get }

    func updateCustomConfigList(with customConfigs: [CustomConfigModel])
    func showEmptyView(tableView: UITableView)
}

class CustomConfigListTableViewDataSourceImpl: WSTableViewDataSource, CustomConfigListTableViewDataSource {

    weak var logicDelegate: CustomConfigListModelDelegate?
    weak var uiDelegate: CustomConfigListViewDelegate?
    var scrollHappened = false
    var customConfigs: [CustomConfigModel] = []

    private var cancellables = Set<AnyCancellable>()

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let hapticFeedbackManager: HapticFeedbackManager
    private let latencyRepository: LatencyRepository
    private let languageManager: LanguageManager

    init(lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         latencyRepository: LatencyRepository,
         languageManager: LanguageManager) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.hapticFeedbackManager = hapticFeedbackManager
        self.latencyRepository = latencyRepository
        self.languageManager = languageManager
        super.init()
        scrollViewDelegate = self

        bind()
    }

    private func bind() {
        self.lookAndFeelRepository.isDarkModeSubject
            .sink {[weak self] _ in
                self?.uiDelegate?.reloadCustomConfigListTableView()
            }
            .store(in: &cancellables)
    }

    func updateCustomConfigList(with customConfigs: [CustomConfigModel]) {
        self.customConfigs = customConfigs
        uiDelegate?.reloadCustomConfigListTableView()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int {
        let count = customConfigs.count
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

        let customConfig = customConfigs[indexPath.row]

        var latency = -1
        if let pingIP = customConfig.serverAddress {
            latency = latencyRepository.getPingData(ip: pingIP)?.latency ?? latency
        }

        if cell.customConfigCellViewModel == nil {
            cell.customConfigCellViewModel = CustomConfigCellModel()
        }

        cell.customConfigCellViewModel?.update(displayingCustomConfig: customConfig,
                                               isDarkMode: lookAndFeelRepository.isDarkMode,
                                               latency: latency)
        cell.delegate = self
        cell.refreshUI()
        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let customConfig = customConfigs[indexPath.row]
        logicDelegate?.setSelectedCustomConfig(customConfig: customConfig)
    }

    func showEmptyView(tableView: UITableView) {
        let view = ListEmptyView(type: .customConfig,
                                 isDarkMode: lookAndFeelRepository.isDarkModeSubject,
                                 activeLanguage: languageManager.activelanguage)
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
        let customConfig = customConfigs[indexPath.row]

        guard let fileId = customConfig.id, let protocolType = customConfig.protocolType else { return nil }

        let deleteAction = SwipeAction(style: .destructive, title: nil) { _, _ in
            self.logicDelegate?.showRemoveAlertForCustomConfig(id: fileId, protocolType: protocolType)
        }
        let editAction = SwipeAction(style: .destructive, title: nil) { _, _ in
            self.logicDelegate?.showEditCustomConfig(customConfig: customConfig)
        }

        // Get dark mode value synchronously
        let isDark = lookAndFeelRepository.isDarkMode
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
            hapticFeedbackManager.run(level: .light)
        }
    }
}

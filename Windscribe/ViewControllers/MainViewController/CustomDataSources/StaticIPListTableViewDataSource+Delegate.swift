//
//  StaticIPListTableViewDataSource+Delegate.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Combine
import UIKit

protocol StaticIPListTableViewDelegate: AnyObject {
    func setSelectedStaticIP(staticIP: StaticIPModel)
    func reloadStaticIPListTableView()
    func hideStaticIPRefreshControl()
    func showStaticIPRefreshControl()
    func handleRefresh()
    func tableViewScrolled(toTop: Bool)
    func addStaticIP()
}

protocol StaticIPListTableViewDataSource: WSTableViewDataSource,
                                          UITableViewDataSource,
                                          WTableViewDataSourceDelegate {
    var delegate: StaticIPListTableViewDelegate? { get set }
    var scrollHappened: Bool { get set }

    func updateStaticIPList(with staticIPs: [StaticIPModel])
    func shouldHideFooter() -> Bool
    func makeEmptyView(tableView: UITableView)
}

class StaticIPListTableViewDataSourceImpl: WSTableViewDataSource, StaticIPListTableViewDataSource {
    weak var delegate: StaticIPListTableViewDelegate?
    var scrollHappened = false

    private var staticIPs: [StaticIPModel] = []
    private var cancellables = Set<AnyCancellable>()

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let hapticFeedbackManager: HapticFeedbackManager
    private let latencyRepository: LatencyRepository
    private let languageManager: LanguageManager

    init(lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         languageManager: LanguageManager,
         latencyRepository: LatencyRepository) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.hapticFeedbackManager = hapticFeedbackManager
        self.languageManager = languageManager
        self.latencyRepository = latencyRepository
        super.init()
        scrollViewDelegate = self

        bind()
    }

    private func bind() {
        self.lookAndFeelRepository.isDarkModeSubject
            .sink {[weak self] _ in
                self?.delegate?.reloadStaticIPListTableView()
            }
            .store(in: &cancellables)

        languageManager.activelanguage
            .sink {[weak self] _ in
                self?.delegate?.reloadStaticIPListTableView()
            }
            .store(in: &cancellables)
    }

    func updateStaticIPList(with staticIPs: [StaticIPModel]) {
        self.staticIPs = staticIPs
        delegate?.reloadStaticIPListTableView()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int {
        let count = staticIPs.count
        if count == 0 {
            delegate?.hideStaticIPRefreshControl()
            tableView.backgroundView?.isHidden = false
            tableView.tableFooterView?.isHidden = true
            tableView.tableHeaderView?.isHidden = true
        } else {
            delegate?.showStaticIPRefreshControl()
            tableView.backgroundView?.isHidden = true
            tableView.tableFooterView?.isHidden = false
            tableView.tableHeaderView?.isHidden = false
        }
        return count
    }

    func shouldHideFooter() -> Bool {
        staticIPs.count == 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifiers.staticIPCellReuseIdentifier, for: indexPath) as? StaticIPTableViewCell
        ?? StaticIPTableViewCell(
            style: .default,
            reuseIdentifier: ReuseIdentifiers.staticIPCellReuseIdentifier)
        let staticIP = staticIPs[indexPath.row]

        var latency = -1
        if let bestNode = staticIP.bestNode, bestNode.forceDisconnect == false {
            latency = latencyRepository.getPingData(ip: bestNode.ip1)?.latency ?? latency
        }

        if cell.staticIPCellViewModel == nil {
            cell.staticIPCellViewModel = StaticIPNodeCellModel()
        }

        cell.staticIPCellViewModel?.update(displayingStaticIP: staticIP,
                                           isDarkMode: lookAndFeelRepository.isDarkMode,
                                           latency: latency)
        cell.refreshUI()
        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let staticIP = staticIPs[indexPath.row]
        delegate?.setSelectedStaticIP(staticIP: staticIP)
    }

    func makeEmptyView(tableView: UITableView) {
        let view = ListEmptyView(type: .staticIP, isDarkMode: lookAndFeelRepository.isDarkModeSubject, activeLanguage: languageManager.activelanguage)
        view.addAction = { [weak self] in
            self?.delegate?.addStaticIP()
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
            hapticFeedbackManager.run(level: .light)
        }
    }
}

//
//  StaticIPListTableViewDataSource+Delegate.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

protocol StaticIPListTableViewDelegate: AnyObject {
    func setSelectedStaticIP(staticIP: StaticIPModel)
    func hideStaticIPRefreshControl()
    func showStaticIPRefreshControl()
    func handleRefresh()
    func tableViewScrolled(toTop: Bool)
    func addStaticIP()
}

class StaticIPListTableViewDataSource: WTableViewDataSource, UITableViewDataSource, WTableViewDataSourceDelegate {
    var staticIPs: [StaticIPModel]?
    weak var delegate: StaticIPListTableViewDelegate?
    var scrollHappened = false
    var viewModel: MainViewModelType
    let disposeBag = DisposeBag()
    lazy var languageManager = Assembler.resolve(LanguageManager.self)

    init(staticIPs: [StaticIPModel]?, viewModel: MainViewModelType) {
        self.viewModel = viewModel
        super.init()
        scrollViewDelegate = self
        self.staticIPs = staticIPs
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let count = staticIPs?.count else { return 0 }
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
        (staticIPs?.count ?? 0) == 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifiers.staticIPCellReuseIdentifier, for: indexPath) as? StaticIPTableViewCell
            ?? StaticIPTableViewCell(
                style: .default,
                reuseIdentifier: ReuseIdentifiers.staticIPCellReuseIdentifier)
        let staticIP = staticIPs?[indexPath.row]
        cell.staticIPCellViewModel = StaticIPNodeCellModel(displayingStaticIP: staticIP)
        cell.bindViews(isDarkMode: viewModel.isDarkMode)
        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let staticIP = staticIPs?[indexPath.row] else { return }
        delegate?.setSelectedStaticIP(staticIP: staticIP)
    }

    func makeEmptyView(tableView: UITableView) {
        let view = ListEmptyView(type: .staticIP,isDarkMode: viewModel.isDarkMode)
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
            HapticFeedbackGenerator.shared.run(level: .light)
        }
    }
}

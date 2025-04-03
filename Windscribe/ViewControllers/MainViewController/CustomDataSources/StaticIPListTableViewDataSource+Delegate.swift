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
}

class StaticIPListTableViewDataSource: WTableViewDataSource, UITableViewDataSource, WTableViewDataSourceDelegate {
    var staticIPs: [StaticIPModel]?
    weak var delegate: StaticIPListTableViewDelegate?
    var scrollHappened = false
    var viewModel: MainViewModelType
    let disposeBag = DisposeBag()
    lazy var languageManager = Assembler.resolve(LanguageManagerV2.self)
    var label: UILabel?

    init(staticIPs: [StaticIPModel]?, viewModel: MainViewModelType) {
        self.viewModel = viewModel
        super.init()
        label = UILabel()
        scrollViewDelegate = self
        self.staticIPs = staticIPs
        languageManager.activelanguage.subscribe(onNext: { [self] _ in
            label?.text = TextsAsset.noStaticIPs
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let count = staticIPs?.count else { return 0 }
        if count == 0 {
            delegate?.hideStaticIPRefreshControl()
            showEmptyView(tableView: tableView)
        } else {
            delegate?.showStaticIPRefreshControl()
            tableView.backgroundView = nil
        }
        return count
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

    func showEmptyView(tableView: UITableView) {
        let emptyView = UIView(frame: tableView.bounds)
        label = UILabel(frame: CGRect(x: 0, y: emptyView.frame.midY - 42, width: emptyView.frame.width, height: 32))
        label?.textAlignment = .center
        label?.font = UIFont.text(size: 19)
        label?.text = TextsAsset.noStaticIPs
        let isDarkMode = (try? viewModel.isDarkMode.value()) ?? true
        label?.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        label?.layer.opacity = 0.4
        if let label = label {
            emptyView.addSubview(label)
        }
        tableView.backgroundView = emptyView
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

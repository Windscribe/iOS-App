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
    var label: UILabel
    init(favNodes: [FavNodeModel]?, viewModel: MainViewModelType) {
        label = UILabel()
        self.viewModel = viewModel
        super.init()
        scrollViewDelegate = self
        self.favNodes = favNodes
        languageManager.activelanguage.subscribe(onNext: { [self] _ in
            label.text = TextsAsset.nothingToSeeHere
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let count = favNodes?.count else { return 0 }
        if count == 0 {
            delegate?.hideFavNodeRefreshControl()
            showEmptyView(tableView: tableView)
        } else {
            delegate?.showFavNodeRefreshControl()
            tableView.backgroundView = nil
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: favNodeCellReuseIdentifier, for: indexPath) as? FavNodeTableViewCell ?? FavNodeTableViewCell(style: .default, reuseIdentifier: favNodeCellReuseIdentifier)
        let node = favNodes?[indexPath.row]
        cell.bindViews(isDarkMode: viewModel.isDarkMode)
        cell.displayingFavNode = node
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
        let emptyView = UIView(frame: tableView.bounds)
        let imageView = UIImageView(frame: CGRect(x: emptyView.frame.midX - 16, y: emptyView.frame.midY - 60, width: 32, height: 28))
        imageView.image = UIImage(named: ImagesAsset.brokenHeart)
        imageView.layer.opacity = 0.4
        emptyView.addSubview(imageView)
        label.frame = CGRect(x: 0, y: imageView.frame.maxY + 10, width: emptyView.frame.width, height: 32)
        label.textAlignment = .center
        label.font = UIFont.text(size: 19)
        label.text = TextsAsset.nothingToSeeHere
        let isDarkMode = (try? viewModel.isDarkMode.value()) ?? true
        label.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        imageView.image = UIImage(named: isDarkMode ? ImagesAsset.DarkMode.brokenHeart : ImagesAsset.brokenHeart)
        label.layer.opacity = 0.4
        emptyView.addSubview(label)
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

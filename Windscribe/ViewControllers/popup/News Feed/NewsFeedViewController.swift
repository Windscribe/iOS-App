//
//  NewsFeedViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import ExpyTableView
import RealmSwift
import RxCocoa
import RxDataSources
import RxSwift
import UIKit

class NewsFeedViewController: WSUIViewController {
    var backButton: LargeTapAreaImageButton!
    var titleLabel: UILabel!
    var tableView: UITableView!
    var viewModel: NewsFeedModelType!
    var logger: FileLogger!
    var accountRouter: AccountRouter!

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Notifications View")
        addViews()
        addAutoLayoutConstraints()
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .dark
        }
        bindView()
    }

    func bindView() {
        let datasource = datasourcesAnimated()
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        viewModel.newsSections.bind(to: tableView.rx.items(dataSource: datasource)).disposed(by: disposeBag)
    }

    func datasourcesAnimated() -> RxTableViewSectionedAnimatedDataSource<NewsSection> {
        return RxTableViewSectionedAnimatedDataSource<NewsSection>(
            configureCell: { [weak self] _, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: noticeCellReuseIdentifier) as? NewsFeedCell ??
                    NewsFeedCell(style: .default, reuseIdentifier: noticeCellReuseIdentifier)
                cell.setViewModel(cellViewModel: item, width: tableView.frame.size.width)
                cell.didTapActionLabel = { promoCode, pcpID in
                    guard let self = self else { return }
                    self.accountRouter.routeTo(to: .upgrade(promoCode: promoCode, pcpID: pcpID), from: self)
                }
                cell.diTapHeader = {
                    self?.viewModel.didTapNotice(at: indexPath.section)
                    tableView.reloadSections([indexPath.section], animationStyle: .automatic)
                }
                return cell
            })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    @objc func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

extension NewsFeedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let model = viewModel.newsSections.value[indexPath.section].items[0]
        if model.collapsed {
            return 48
        }
        guard let message = model.message,
              let messageData = message.data(using: .utf8)
        else { return UITableView.automaticDimension }
        let lblDescLong = UITextView()
        lblDescLong.translatesAutoresizingMaskIntoConstraints = true
        lblDescLong.isScrollEnabled = false
        lblDescLong.htmlText(htmlData: messageData,
                             font: .bold(size: 14),
                             foregroundColor: UIColor.whiteWithOpacity(opacity: 0.5))
        var frame = lblDescLong.frame
        frame.size.width = tableView.frame.size.width - 20
        lblDescLong.frame = frame
        lblDescLong.sizeToFit()

        if model.action != nil {
            return lblDescLong.frame.size.height + 74
        } else {
            return lblDescLong.frame.size.height + 44
        }
    }

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_: UITableView,
                   heightForFooterInSection _: Int) -> CGFloat
    {
        return 16
    }

    func tableView(_: UITableView,
                   viewForFooterInSection _: Int) -> UIView?
    {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
}

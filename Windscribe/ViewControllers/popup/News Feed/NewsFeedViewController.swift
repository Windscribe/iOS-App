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
import SafariServices
import UIKit

class NewsFeedViewController: WSNavigationViewController {
    var tableView: UITableView!
    var viewModel: NewsFeedModelType!
    var logger: FileLogger!
    var accountRouter: AccountRouter!
    private let datasource = NewsfeedDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD("NewsFeed", "Displaying Newsfeed View")
        addViews()
        addAutoLayoutConstraints()
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .dark
        }
        setupViews()
        bindView()
    }

    private func setupViews() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(NewsFeedDataCell.self, forCellReuseIdentifier: "NewsFeedDataCell")
        tableView.dataSource = datasource
        datasource.didTapExpandIcon = { [weak self] id in
            self?.viewModel.didTapToExpand(id: id)
        }
        datasource.didTapAction = { [weak self] action in
            self?.viewModel.didTapAction(action: action)
        }
    }

    private func bindView() {
        viewModel.newsfeedData.bind(onNext: { [weak self] sections in
            self?.datasource.setData(items: sections)
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        viewModel.viewToLaunch.bind(onNext: { view in
            switch view {
            case let .safari(url):
                self.logger.logD("NewsFeed", "Opening url in safari: \(url)")
                self.openLink(url: url)
            case let .payment(promo, pcpid):
                self.logger.logD("NewsFeed", "Launching payment plans with promo: \(promo)")
                self.accountRouter.routeToPayments(to: .upgrade(promoCode: promo, pcpID: pcpid), from: self)
            default: ()
            }
        }).disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
}

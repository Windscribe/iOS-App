//
//  ViewLeaderboardViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-13.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxDataSources
import RxSwift
import UIKit

class ViewLeaderboardViewController: WSNavigationViewController {
    var tableView: UITableView!
    var viewModel: ViewLeaderboardViewModelType!

    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        titleLabel.text = TextsAsset.Preferences.leaderboard
        bindViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    private func bindViews() {
        let dataSource = RxTableViewSectionedReloadDataSource<ScoreSection>(
            configureCell: { _, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: leaderboardCellReuseIdentifier, for: indexPath)
                    as? LeaderboardTableViewCell
                    ?? LeaderboardTableViewCell(style: .default, reuseIdentifier: leaderboardCellReuseIdentifier)
                cell.bindViews(isDarkMode: self.viewModel.isDarkMode)
                cell.setScore(with: item)
                return cell
            },
            titleForHeaderInSection: { _, _ in
                ""
            }
        )
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        viewModel.scoresSection.bind(to: tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        viewModel.load()

        viewModel.isDarkMode.subscribe(onNext: { [self] in
            setupViews(isDark: $0)
        }).disposed(by: disposeBag)
    }
}

extension ViewLeaderboardViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

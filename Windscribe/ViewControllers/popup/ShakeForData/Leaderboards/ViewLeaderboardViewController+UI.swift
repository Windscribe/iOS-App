//
//  ViewLeaderboardViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-13.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension ViewLeaderboardViewController {

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addAutoLayoutConstraints()
    }

    func addViews() {
        tableView = PlainTableView()
        tableView.layer.cornerRadius = 0
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 50
        tableView.register(LeaderboardTableViewCell.self, forCellReuseIdentifier: leaderboardCellReuseIdentifier)
        self.view.addSubview(tableView)
    }

    func addAutoLayoutConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // tableView
            tableView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 24),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

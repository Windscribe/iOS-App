//
//  PreferencesViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-01.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension PreferencesMainViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 452)
        tableViewHeightConstraint?.isActive = true
        tableView.heightAnchor.constraint(equalToConstant: 452).isActive = true
        tableView.makeTopAnchor(with: titleLabel, constant: 24)
        tableView.makeLeadingAnchor(constant: 16)
        tableView.makeTrailingAnchor(constant: 16)

        shawdowView.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        shawdowView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor).isActive = true
        shawdowView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor).isActive = true
        shawdowView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true

        guard let actionButton = actionButton,
              let loginButton = loginButton
        else {
            return
        }
        actionButtonBottomConstraint = NSLayoutConstraint(item: actionButton, attribute: .bottom, relatedBy: .equal, toItem: getMoreDataView, attribute: .top, multiplier: 1.0, constant: -24)
        view.addConstraints([
            actionButtonBottomConstraint,
            NSLayoutConstraint(item: actionButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50),
            NSLayoutConstraint(item: actionButton, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 28),
            NSLayoutConstraint(item: actionButton, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -28)
        ])
        if actionButton.isHidden == false {
            loginButtonBottomConstraint = NSLayoutConstraint(item: loginButton, attribute: .bottom, relatedBy: .equal, toItem: actionButton, attribute: .top, multiplier: 1.0, constant: -24)
        } else {
            loginButtonBottomConstraint = NSLayoutConstraint(item: loginButton, attribute: .bottom, relatedBy: .equal, toItem: getMoreDataView, attribute: .top, multiplier: 1.0, constant: -24)
        }
        view.addConstraints([
            loginButtonBottomConstraint,
            NSLayoutConstraint(item: loginButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50),
            NSLayoutConstraint(item: loginButton, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 28),
            NSLayoutConstraint(item: loginButton, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -28)
        ])
    }

    func addViews() {
        view.addSubview(shawdowView)

        tableView = PlainTableView()
        tableView.layer.cornerRadius = 8
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 50
        tableView.register(PreferencesTableViewCell.self, forCellReuseIdentifier: preferencesCellReuseIdentifier)
        tableViewContenSizeObserve = tableView.observe(\.contentSize, options: [.new], changeHandler: { [weak self] tableView, _ in
            self?.tableViewHeightConstraint?.constant = tableView.contentSize.height
        })
        view.addSubview(tableView)

        actionButton = UIButton(type: .system)
        actionButton.tintColor = UIColor.midnight
        actionButton.titleLabel?.font = UIFont.text(size: 16)
        actionButton.layer.cornerRadius = 24
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        actionButton.titleLabel?.lineBreakMode = .byWordWrapping
        actionButton.titleLabel?.textAlignment = .center
        view.addSubview(actionButton)

        loginButton = UIButton(type: .system)
        loginButton.isHidden = true
        loginButton.tintColor = UIColor.midnight
        loginButton.titleLabel?.font = UIFont.text(size: 16)
        loginButton.layer.cornerRadius = 24
        view.addSubview(loginButton)
    }

    @objc func displayElementsForPrefferedAppearence() {
        // self.displayForPrefferedAppearence()
        tableView.reloadData()
        shawdowView.backgroundColor = viewModel.isDarkTheme() ? UIColor.whiteWithOpacity(opacity: 0.08) : .midnightWithOpacity(opacity: 0.08)
    }
}

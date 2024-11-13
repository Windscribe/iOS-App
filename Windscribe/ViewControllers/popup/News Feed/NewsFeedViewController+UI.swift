//
//  NewsFeedViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import ExpyTableView

extension NewsFeedViewController {

    func addViews() {
        view.backgroundColor = UIColor.lightMidnight

        backButton = LargeTapAreaImageButton()
        backButton.setImage(UIImage(named: ImagesAsset.closeIcon), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)

        titleLabel = UILabel()
        titleLabel.text = TextsAsset.NewsFeed.title
        titleLabel.font = UIFont.bold(size: 24)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        view.addSubview(titleLabel)

        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        tableView.layer.cornerRadius = 0
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = true
        tableView.bounces = true
        tableView.backgroundColor = UIColor.clear
        tableView.estimatedRowHeight = 150
        tableView.sectionFooterHeight = 50
        tableView.register(NewsFeedCell.self, forCellReuseIdentifier: noticeCellReuseIdentifier)
        view.addSubview(tableView)

    }

    func addAutoLayoutConstraints() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        if UIScreen.hasTopNotch {
             view.addConstraints([
                 NSLayoutConstraint(item: backButton as Any, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 70)
                 ])
         } else {
             view.addConstraints([
                 NSLayoutConstraint(item: backButton as Any, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 32)
                 ])
         }
        view.addConstraints([
            NSLayoutConstraint(item: backButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: backButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: backButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 32)
            ])
        view.addConstraints([
            NSLayoutConstraint(item: titleLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: backButton, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: titleLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 32)
            ])
        view.addConstraints([
            NSLayoutConstraint(item: tableView as Any, attribute: .top, relatedBy: .equal, toItem: titleLabel, attribute: .bottom, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: tableView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: tableView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: tableView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])
    }
}

//
//  AboutViewController.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-07-28.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class AboutViewController: WSNavigationViewController {
    var viewModel: AboutViewModelType!, logger: FileLogger!

    lazy var tableView: DynamicSizeTableView = {
        let tableView = DynamicSizeTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        tableView.backgroundView?.backgroundColor = .clear
        return tableView
    }()

    lazy var backgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Help View")
        titleLabel.text = About.about
        view.backgroundColor = UIColor.darkGray
        addViews()
        bindViews()
    }

    private func bindViews() {
        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            self.setupTheme(isDark: isDark)
        }).disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true

        backgroundView.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
    }

    func addViews() {
        view.addSubview(backgroundView)
        view.addSubview(tableView)

        tableView.delegate = self
        tableView.dataSource = self
        AboutViewCell.registerClass(in: tableView)
    }

    private func setupTheme(isDark: Bool) {
        backgroundView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark)
        super.setupViews(isDark: isDark)
        tableView.reloadData()
    }
}

// MARK: - Extensions

extension AboutViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return viewModel.numberOfRowsInSection()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AboutViewCell.dequeueReusableCell(in: tableView, for: indexPath)
        let data = viewModel.celldata(at: indexPath)
        cell.cellDivider.isHidden = data == .softwareLicenses ? true : false
        cell.aboutItem = data
        cell.bindViews(isDarkMode: viewModel.isDarkMode)
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = viewModel.celldata(at: indexPath)
        openLink(url: data.url)
    }
}

//
//	LanguageViewController.swift
//	Windscribe
//
//	Created by Thomas on 21/04/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit

class LanguageViewController: WSNavigationViewController {
    var viewModel: LanguageViewModelType!

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        LanguageTableViewCell.registerClass(in: tableView)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func setupUI() {
        titleLabel.text = TextsAsset.General.language
        view.addSubview(tableView)
        tableView.makeTopAnchor(with: titleLabel, constant: 16)
        tableView.makeLeadingAnchor()
        tableView.makeTrailingAnchor()
        tableView.makeBottomAnchor()

        tableView.delegate = self
        tableView.dataSource = self
    }

    private func bindings() {
        viewModel?.didUpdateLanguage = { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            self.setupViews(isDark: isDark)
        }).disposed(by: disposeBag)
    }
}

extension LanguageViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = LanguageTableViewCell.dequeueReusableCell(in: tableView, for: indexPath)
        cell.configData(viewModel.dataForCell(at: indexPath))
        cell.bindView(isDarkMode: viewModel.isDarkMode)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectedLanguage(at: indexPath)
        navigationController?.popViewController(animated: true)
    }
}

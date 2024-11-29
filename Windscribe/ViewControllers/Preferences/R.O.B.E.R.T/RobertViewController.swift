//
//  RobertViewController.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-12-16.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

class RobertViewController: WSNavigationViewController, UIScrollViewDelegate {
    var logger: FileLogger!, viewModel: RobertViewModelType!

    var tableView: DynamicSizeTableView!
    var robertFilters: [RobertFilter]?
    var buttonToggled: Int? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Robert View")
        view.backgroundColor = UIColor.darkGray
        titleLabel.text = TextsAsset.Preferences.robert
        setupViews()

        bindData()
    }

    private func  bindData() {
        viewModel.loadRobertFilters()
        viewModel.robertFilters.bind(onNext: { filters in
            self.robertFilters = filters
            if let optionToggled = self.buttonToggled {
                self.tableView.reloadRows(at: [IndexPath(row: optionToggled, section: 0)], with: .automatic)
            } else {
                self.tableView.reloadData()
            }
        }).disposed(by: disposeBag)
        viewModel.showProgress.bind(onNext: { show in
            DispatchQueue.main.async {
                if show {
                    self.showLoading()
                } else {
                    self.endLoading()
                }
            }
        }).disposed(by: disposeBag)
        viewModel.showError.bind(onNext: { error in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.viewModel.alertManager.showSimpleAlert(viewController: self, title: "Error", message: error, buttonText: "Ok")

                }
            }
        }).disposed(by: disposeBag)
        viewModel.isDarkMode.subscribe { data in
            self.setupViews(isDark: data)
        }.disposed(by: disposeBag)
        viewModel.urlToOpen.bind(onNext: { url in
            if let url = url {
                self.openLink(url: url)
            }
        }).disposed(by: disposeBag)
    }

    private func setupViews() {
        tableView = DynamicSizeTableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.clear
        RobertFilterCell.registerClass(in: tableView)
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        tableView.makeTopAnchor(with: titleLabel, constant: 8)
        tableView.makeLeadingAnchor(constant: 16)
        tableView.makeTrailingAnchor(constant: 16)
        tableView.makeBottomAnchor()
    }

    @objc func handleLearnMoreTap() {
        viewModel.handleLearnMoreTap()
    }

    @objc func handleCustomRulesTap() {
        viewModel.handleCustomRulesTap()

    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }
}

extension RobertViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return robertFilters?.count ?? 0
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = RobertFilterCell.dequeueReusableCell(in: tableView, for: indexPath)
        cell.setupSubviews(isDarkMode: viewModel.isDarkMode)
        cell.robertFilter = robertFilters?[indexPath.row]
        cell.filterSwitchTapArea.addTarget(self, action: #selector(toggleTap), for: .touchUpInside)
        cell.filterSwitchTapArea.tag = indexPath.row
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = RobertHeaderView(isDarkMode: viewModel.isDarkMode)
        view.contentViewAction = {[weak self] in
            self?.handleLearnMoreTap()
        }
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = RobertFooterView(isDarkMode: viewModel.isDarkMode)
        view.contentViewAction = { [weak self] in
            self?.handleCustomRulesTap()
        }
        return view
    }
}

extension RobertViewController {
    @objc func toggleTap(_ button: UIButton) {
        if (try? viewModel.updadeinProgress.value()) ?? false {
            return
        }
        buttonToggled = button.tag
        viewModel.ruleUpdateTapped(number: button.tag)
    }
}

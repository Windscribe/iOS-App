//
//	AccountViewController.swift
//	Windscribe
//
//	Created by Thomas on 20/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import RxSwift

class AccountViewController: WSNavigationViewController {
    // MARK: - State properties
    var viewModel: AccountViewModelType!
    var router: AccountRouter?
    var logger: FileLogger!

    // MARK: - UI properties
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()

    // MARK: - UI Events

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = TextsAsset.Account.title

        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4).isActive = true
        tableView.makeLeadingAnchor(constant: 16)
        tableView.makeTrailingAnchor(constant: 16)
        tableView.makeBottomAnchor()

        registerCells()
        tableView.delegate = self
        tableView.dataSource = self

        bindViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        viewModel.loadSession().observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [self] _ in
                self.updateUI()
            }, onFailure: { _ in }).disposed(by: disposeBag)
    }

    private func bindViews() {
        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            self.setupViews(isDark: isDark)
        }).disposed(by: disposeBag)
    }

    private func updateUI() {
        DispatchQueue.main.async { [self] in
            tableView.dataSource = self
            tableView.reloadData()
        }
    }

    private func registerCells() {
        AccountTableViewCell.registerClass(in: tableView)
        AccountEditCell.registerClass(in: tableView)
        AccountConfirmEmailCell.registerClass(in: tableView)
        AccountEmailCell.registerClass(in: tableView)
    }
}

// MARK: - Extensions
extension AccountViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = viewModel.celldata(at: indexPath)
        switch data {
        case .email:
            let cell = AccountEmailCell.dequeueReusableCell(in: tableView, for: indexPath)
            cell.bindView(isDarkMode: viewModel.isDarkMode)
            cell.setType(.email, item: data)
            cell.indexPath = indexPath
            cell.delegate = self
            return cell
        case .emailPro:
            let cell = AccountEmailCell.dequeueReusableCell(in: tableView, for: indexPath)
            cell.bindView(isDarkMode: viewModel.isDarkMode)
            cell.setType(.emailPro, item: data)
            cell.indexPath = indexPath
            cell.delegate = self
            return cell
        case .emailEmpty:
            let cell = AccountEmailCell.dequeueReusableCell(in: tableView, for: indexPath)
            cell.bindView(isDarkMode: viewModel.isDarkMode)
            cell.setType(.emptyEmail, item: data)
            cell.indexPath = indexPath
            cell.delegate = self
            return cell
        case .confirmEmail:
            let cell = AccountEmailCell.dequeueReusableCell(in: tableView, for: indexPath)
            cell.bindView(isDarkMode: viewModel.isDarkMode)
            cell.setType(.confirmEmail, item: data)
            cell.indexPath = indexPath
            cell.delegate = self
            cell.resendEmailAction = { [weak self] in
                self?.navigateToConfirmEmailVC()
            }
            return cell
        case .editAccount:
            let cell = AccountEditCell.dequeueReusableCell(in: tableView, for: indexPath)
            cell.bindView(isDarkMode: viewModel.isDarkMode)
            cell.accoutItem = data
            return cell
        default:
            let cell = AccountTableViewCell.dequeueReusableCell(in: tableView, for: indexPath)
            cell.delegate = self
            cell.indexPath = indexPath
            cell.bindViews(isDarkMode: viewModel.isDarkMode)
            cell.configData(item: data)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = AccountHeaderView(isDarkMode: viewModel.isDarkMode)
        view.label.text = viewModel.titleForHeader(in: section)
        return view
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = viewModel.celldata(at: indexPath)
        switch data {
        case .editAccount:
            handleEditAccount()
        default: break
        }
    }
}

extension AccountViewController {
    private func resendConfirmEmail() {
        showLoading()
        viewModel.resendConfirmEmail(success: { [weak self] in
            self?.endLoading()
            self?.viewModel.alertManager.showSimpleAlert(viewController: self,
                                                title: TextsAsset.ConfirmationEmailSentAlert.title,
                                                message: TextsAsset.ConfirmationEmailSentAlert.message,
                                                buttonText: TextsAsset.okay)
        }, failure: { [weak self] msg in
            self?.endLoading()
            self?.viewModel.alertManager.showSimpleAlert(viewController: self,
                                                title: TextsAsset.ConfirmationEmailSentAlert.title,
                                                message: msg,
                                                buttonText: TextsAsset.okay)
        })
    }

    private func navigateAddEmailViewController() {
        router?.routeTo(to: RouteID.enterEmailVC, from: self)
    }

    private func navigateToConfirmEmailVC() {
        router?.routeTo(to: RouteID.confirmEmail(delegate: self), from: self)
    }

    private func navigateUpgradeViewController() {
        router?.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil), from: self)

    }

    private func handleEditAccount() {
        showLoading()
        viewModel.getWebSession(success: { [weak self] url in
            self?.endLoading()
            DispatchQueue.main.async { [weak self] in
                self?.openLink(url: url)
            }
        }, failure: { [weak self] msg in
            self?.endLoading()
            self?.viewModel.alertManager.showSimpleAlert(
                viewController: self,
                title: TextsAsset.error,
                message: msg,
                buttonText: TextsAsset.okay
            )
        })
    }
}

extension AccountViewController: AccountEmailCellDelegate, AccountTableViewCellDelegate {
    func addEmailButtonTapped(indexPath: IndexPath) {
        let data = viewModel.celldata(at: indexPath)
        if data.needAddEmail {
            navigateAddEmailViewController()
        }
    }

    func upgradeButtonTapped(indexPath: IndexPath) {
        let data = viewModel.celldata(at: indexPath)
        if data.needUpgradeAccount {
            navigateUpgradeViewController()
        }

    }
}

extension AccountViewController: ConfirmEmailViewControllerDelegate {
    func dismissWith(action: ConfirmEmailAction) {
        router?.dismissPopup(action: action, navigationVC: self.navigationController)
    }
}

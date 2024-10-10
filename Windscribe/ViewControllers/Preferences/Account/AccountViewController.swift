//
//    AccountViewController.swift
//    Windscribe
//
//    Created by Thomas on 20/05/2022.
//    Copyright © 2022 Windscribe. All rights reserved.
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
        tableView.isScrollEnabled = true
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
        viewModel.cancelAccountState.subscribe(onNext: { state in
            self.logger.logD(self, "Cancel account state: \(state)")
            switch state {
                case .initial:
                    self.endLoading()
                case .loading:
                    self.showLoading()
                case .error(let error):
                    self.endLoading()
                    self.viewModel.alertManager.showSimpleAlert(
                        viewController: self,
                        title: TextsAsset.error,
                        message: error,
                        buttonText: TextsAsset.okay
                    )
                case .success:
                    self.endLoading()
                    self.viewModel.logoutUser()

            }
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
        LazyTableViewCell.registerClass(in: tableView)
        VoucherCodeTableViewCell.registerClass(in: tableView)
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
        case .cancelAccount:
            let cell = AccountEditCell.dequeueReusableCell(in: tableView, for: indexPath)
            cell.bindView(isDarkMode: viewModel.isDarkMode)
            cell.accoutItem = data
            return cell
        case .lazyLogin:
            let cell = LazyTableViewCell.dequeueReusableCell(in: tableView, for: indexPath)
            cell.delegate = self
            return cell
        case .voucherCode:
            let cell = VoucherCodeTableViewCell.dequeueReusableCell(in: tableView, for: indexPath)
            cell.delegate = self
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
            case .cancelAccount:
                handleCancelAccount()
            default: break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            return 120
        }
        return UITableView.automaticDimension
    }

    func showEnterCodeDialog() {
        let alert = UIAlertController(title: NSLocalizedString(TextsAsset.Account.enterCode, comment: ""), message: nil, preferredStyle: .alert)

            // Add a text field to the alert controller
            alert.addTextField { textField in
                textField.placeholder = NSLocalizedString(TextsAsset.Account.enterCodeHere, comment: "")
                textField.autocapitalizationType = .allCharacters
                textField.autocorrectionType = .no
                textField.keyboardType = .default
                textField.textAlignment = .center
                textField.tag = 0
                textField.delegate = self
            }

            // Add actions to the alert controller
            let confirmAction = UIAlertAction(title: NSLocalizedString("Enter", comment: ""), style: .default) { [weak self] _ in
                guard let textField = alert.textFields?.first else { return }
                let code = textField.text ?? ""
                print(code)
                self?.showLoading()
                self?.viewModel.verifyCodeEntered(code: code,
                                                  success: { [weak self] in
                                                      self?.endLoading()
                                                      self?.viewModel.alertManager.showSimpleAlert(viewController: self,
                                                                                                   title: TextsAsset.Account.lazyLogin,
                                                                                                   message: TextsAsset.Account.lazyLoginSuccess,
                                                                                                   buttonText: TextsAsset.okay)
                                                  },
                                                  failure: { [weak self] msg in
                                                      self?.endLoading()
                    self?.router?.routeTo(to: .errorPopup(message: msg, dismissAction: nil), from: self!)
                                                  })
            }

            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                // No need to dismiss manually as the .cancel action will do it
            }

            alert.addAction(confirmAction)
            alert.addAction(cancelAction)

            // Show the alert
            self.present(alert, animated: true) {
                // Focus on the text field when the alert is presented
                alert.textFields?.first?.becomeFirstResponder()
            }
        }

    func showEnterVoucherCodeDialog() {
        let alert = UIAlertController(title: NSLocalizedString(TextsAsset.voucherCode, comment: ""), message: nil, preferredStyle: .alert)

        // Add a text field to the alert controller
        alert.addTextField { textField in
            textField.autocapitalizationType = .allCharacters
            textField.autocorrectionType = .no
            textField.keyboardType = .default
            textField.textAlignment = .center
            textField.delegate = self
            textField.tag = 1
        }

        // Add actions to the alert controller
        let confirmAction = UIAlertAction(title: NSLocalizedString("Enter", comment: ""), style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first else { return }
            let code = textField.text ?? ""
            print(code)
            self?.showLoading()
            self?.viewModel.verifyVoucherEntered(code: code,
                                                 success: { [weak self] response in
                self?.logger.logD(self, "Claimed voucher code: \(code)")
                self?.endLoading()
                self?.handleClaimVoucherResponse(response)
            },
                                                 failure: { [weak self] msg in
                self?.logger.logD(self, "claim voucher request failed with error: \(msg)")
                self?.endLoading()
                self?.router?.routeTo(to: .errorPopup(message: msg, dismissAction: nil), from: self!)
            })
        }

        let cancelAction = UIAlertAction(title: TextsAsset.cancel, style: .cancel) { _ in

        }

        alert.addAction(confirmAction)
        alert.addAction(cancelAction)

        // Show the alert
        self.present(alert, animated: true) {
            // Focus on the text field when the alert is presented
            alert.textFields?.first?.becomeFirstResponder()
        }
    }

    func handleClaimVoucherResponse(_ response: ClaimVoucherCodeResponse) {
        if response.isClaimed {
            self.logger.logD(self, "voucher code is claimed")
            DispatchQueue.main.async { [weak self] in
                self?.viewModel.alertManager.showSimpleAlert(viewController: self!,
                                                             title: TextsAsset.voucherCode,
                                                             message: TextsAsset.Account.voucherCodeSuccessful,
                                                             buttonText: TextsAsset.okay)
            }
            viewModel.loadSession().observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [self] _ in
                    self.updateUI()
                }, onFailure: { _ in }).disposed(by: disposeBag)
        } else if (response.emailRequired == true) {
            self.logger.logD(self, "email is required for claiming voucher")
            self.router?.routeTo(to: .errorPopup(message: TextsAsset.Account.emailRequired, dismissAction: nil), from: self)
        } else if (response.isUsed == true) {
            self.logger.logD(self, "voucher is already claimed")
            self.router?.routeTo(to: .errorPopup(message: TextsAsset.Account.voucherUsedMessage, dismissAction: nil), from: self)
        } else {
            self.logger.logD(self, "invalid voucher")
            self.router?.routeTo(to: .errorPopup(message: TextsAsset.Account.invalidVoucherCode, dismissAction: nil), from: self)
        }

    }
}

extension AccountViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == 0 {
            let currentText = textField.text ?? ""
            let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)

            // Enforce length limit
            if updatedText.count > 9 {
                return false
            }

            // Handle automatic insertion of dash
            let formattedText = formatCodeText(updatedText)
            textField.text = formattedText
            return false
        }
        return true
    }

    private func formatCodeText(_ text: String) -> String {
        var formattedText = text
        if formattedText.count > 4 {
            let index = formattedText.index(formattedText.startIndex, offsetBy: 4)
            if formattedText[index] != "-" {
                formattedText.insert("-", at: index)
            }
        }
        return formattedText
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

    private func handleCancelAccount() {
        logger.logD(self, "Showing delete account popup.")
        viewModel.alertManager.askPasswordToDeleteAccount().subscribe(onSuccess: { password in
            if let password = password, !password.isEmpty {
                self.viewModel.cancelAccount(password: password)
            } else {
                self.logger.logD(self, "Entered password is nil/empty.")
            }
        }, onFailure: { _ in }).disposed(by: disposeBag)
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

extension AccountViewController: LazyViewDelegate {
    func lazyViewDidSelect() {
        showEnterCodeDialog()
    }
}

extension AccountViewController: VoucherDelegate {
    func voucherViewDidSelect() {
        showEnterVoucherCodeDialog()
    }
}

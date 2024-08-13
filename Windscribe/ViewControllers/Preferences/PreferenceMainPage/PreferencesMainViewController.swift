//
//  PreferencesMainViewController.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2023-12-19.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
class PreferencesMainViewController: WSNavigationViewController {

    // MARK: - State properties
    var router: PreferenceMainRouter!, viewModel: PreferencesMainViewModel!, logger: FileLogger!

    // MARK: - UIElements
    lazy var shawdowView: UIView = {
        let view = WSView()
        view.layer.cornerRadius = 8
        view.backgroundColor = viewModel.isDarkTheme() ? UIColor.whiteWithOpacity(opacity: 0.08) : .midnightWithOpacity(opacity: 0.08)

        return view
    }()

    var tableView: UITableView!
    var tableViewHeightConstraint: NSLayoutConstraint?
    var tableViewContenSizeObserve: NSKeyValueObservation?
    var actionButton, loginButton: UIButton!
    var actionButtonBottomConstraint, loginButtonBottomConstraint: NSLayoutConstraint!

    // MARK: - UI Events
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Preferences View")
        addViews()
        addGetMoreDataViews()
        addAutolayoutConstraintsForGetMoreDataViews()
        displayLeftDataInformation()
        setupLocalized()
        bindViews()
        viewModel.getActionButtonDisplay()
    }

    override func setupLocalized() { }

    deinit {
        tableViewContenSizeObserve?.invalidate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func bindViews() {
        actionButton.rx.tap.bind { [weak self] in
            self?.actionButtonTapped(tag: self?.actionButton.tag)
        }.disposed(by: disposeBag)
        loginButton.rx.tap.bind { [self] in
            self.router?.routeTo(to: RouteID.login, from: self)
        }.disposed(by: disposeBag)
        viewModel.actionDisplay.bind { [self] display in
            switch display {
            case .email:
                displayAddEmail()
            case .emailGet10GB:
                displayAddEmailGet10Gb()
            case .setupAccountAndLogin:
                displaySetupAccount()
                displayLogin()
            case .setupAccount:
                displaySetupAccount()
            case .confirmEmail:
                displayConfirmEmail()
            case .hideAll:
                actionButton.isHidden = true
                loginButton.isHidden = true
            }
        }.disposed(by: disposeBag)

        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            self.shawdowView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark)
            self.setupViews(isDark: isDark)
            self.tableView.reloadData()
        }).disposed(by: disposeBag)

        viewModel.currentLanguage.bind(onNext: { _ in
            self.updateLocalizedText()
        }).disposed(by: disposeBag)
    }

    // MARK: - UI helper functions

   private func updateLocalizedText() {
        titleLabel.text = TextsAsset.Preferences.title
        loginButton.setTitle("\(TextsAsset.login)", for: .normal)
        tableView.reloadData()
        viewModel.getActionButtonDisplay()
        displayLeftDataInformation()
        getMoreDataButton.setTitle(TextsAsset.getMoreData.uppercased(), for: .normal)
    }

    func displayAddEmailGet10Gb() {
        actionButton.tag = 1
        actionButton.backgroundColor = UIColor.unconfirmedYellow
        actionButton.setTitle("\(TextsAsset.addEmail) (\(TextsAsset.get10GbAMonth))", for: .normal)
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.addIcon(icon: ImagesAsset.warningBlack)
    }

    func displayAddEmail() {
        actionButton.tag = 4
        actionButton.backgroundColor = UIColor.unconfirmedYellow
        actionButton.setTitle("\(TextsAsset.addEmail)", for: .normal)
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.addIcon(icon: ImagesAsset.warningBlack)
        if let actionButton = actionButton {
            actionButtonBottomConstraint = NSLayoutConstraint(item: actionButton, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: -24)
        }
        self.view.setNeedsLayout()
    }

    func displayLogin() {
        loginButton.isHidden = false
        loginButton.tag = 2
        loginButton.backgroundColor = UIColor.backgroundBlue
        loginButton.setTitle("\(TextsAsset.login)", for: .normal)
        loginButton.setTitleColor(UIColor.white, for: .normal)
        self.view.setNeedsLayout()
    }

    func displaySetupAccount() {
        actionButton.tag = 3
        actionButton.backgroundColor = UIColor.unconfirmedYellow
        actionButton.setTitle("\(TextsAsset.setupAccount)", for: .normal)
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.addIcon(icon: ImagesAsset.warningBlack)
        if let actionButton = actionButton {
            actionButtonBottomConstraint = NSLayoutConstraint(item: actionButton,
                                                              attribute: .bottom,
                                                              relatedBy: .equal,
                                                              toItem: getMoreDataView,
                                                              attribute: .top,
                                                              multiplier: 1.0,
                                                              constant: -24)
        }
        view.setNeedsLayout()
    }

    func displayConfirmEmail() {
        actionButton.tag = 5
        actionButton.backgroundColor = UIColor.unconfirmedYellow
        actionButton.setTitle("\(TextsAsset.EmailView.confirmEmail)", for: .normal)
        actionButton.setTitleColor(UIColor.midnight, for: .normal)
        actionButton.addIcon(icon: ImagesAsset.warningBlack)
        if let actionButton = actionButton {
            actionButtonBottomConstraint = NSLayoutConstraint(item: actionButton, attribute: .bottom, relatedBy: .equal, toItem: self.getMoreDataView, attribute: .top, multiplier: 1.0, constant: -24)
        }
        self.view.setNeedsLayout()
    }

    private func actionButtonTapped(tag: Int?) {
        switch tag {
        case 1:
            router?.routeTo(to: RouteID.enterEmail, from: self)
        case 2:
            router?.routeTo(to: RouteID.login, from: self)
        case 3:
            router?.routeTo(to: RouteID.signup(claimGhostAccount: true), from: self)
        case 4:
            router?.routeTo(to: RouteID.enterEmail, from: self)
        case 5:
            router?.routeTo(to: RouteID.confirmEmail(delegate: self), from: self)
        default:
            return
        }
    }

    private func signoutButtonTapped() {
        logger.logD(self, "User tapped to sign out.")
        HapticFeedbackGenerator.shared.run(level: .medium)
        viewModel.alertManager.showYesNoAlert(title: TextsAsset.Preferences.logout,
                                           message: TextsAsset.Preferences.logOutAlert ,
                                           completion: { result in
            if result {
                self.viewModel?.logoutUser()
            }
        })
    }

    // helper functions
    override func displayLeftDataInformation() {
        if getMoreDataLabel == nil { return }
        getMoreDataLabel.text = "\(viewModel.getDataLeft()) \(TextsAsset.left.uppercased())"
        if viewModel.isUserPro() {
            getMoreDataView.isHidden = true
            getMoreDataLabel.isHidden = true
            getMoreDataButton.isHidden = true
        }
    }
}

// MARK: - Extensions
extension PreferencesMainViewController: ConfirmEmailViewControllerDelegate {
    func dismissWith(action: ConfirmEmailAction) {
        router.dismissPopup(action: action, navigationVC: self.navigationController)
    }

}

extension PreferencesMainViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if viewModel?.isUserGhost() ?? false {
            return 7
        }
        return 8
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 4 && (viewModel?.isUserPro() == true || viewModel?.isUserGhost() == true) {
            return 0.01
        }
        return 48
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: preferencesCellReuseIdentifier, for: indexPath) as?
                PreferencesTableViewCell else {
            return UITableViewCell()
        }
        cell.arrowIcon.isHidden = false
        cell.cellDivider.isHidden = false
        if let preferenceItem = viewModel?.getPreferenceItem(for: indexPath.row) {
            cell.displayingItem = preferenceItem
        }
        cell.isHidden = indexPath.row == 4 && (viewModel?.isUserPro() == true || viewModel?.isUserGhost() == true)
        if indexPath.row == 7 {
            cell.arrowIcon.isHidden = true
            cell.cellDivider.isHidden = true
        }
        cell.bindViews(isDarkMode: viewModel.isDarkMode)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        HapticFeedbackGenerator.shared.run(level: .medium)
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            router?.routeTo(to: RouteID.general, from: self)

        case 1:
            if viewModel?.isUserGhost() ?? false {
                if viewModel?.isUserPro() == true && sessionManager.session?.hasUserAddedEmail == false {
                    router?.routeTo(to: RouteID.signup(claimGhostAccount: true), from: self)
                } else {
                    router?.routeTo(to: RouteID.ghostAccount, from: self)
                }
            } else {
                router?.routeTo(to: RouteID.account, from: self)
            }
        case 3:
            router?.routeTo(to: RouteID.robert, from: self)
        case 2:
            router?.routeTo(to: RouteID.connection, from: self)
        case 4:
            router?.routeTo(to: RouteID.shareWithFriends, from: self)
        case 5:
            router?.routeTo(to: RouteID.help, from: self)
        case 6:
            router?.routeTo(to: RouteID.about, from: self)

        case 7:
            self.signoutButtonTapped()
        default:
            break
        }
    }

}

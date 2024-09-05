//
//  PreferencesMainViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 01/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

enum PreferencesType {
    case general
    case account
    case connection
    case viewLog
    case sendLog
    case signOut

    var isPrimary: Bool {
        switch self {
        case .general, .account, .connection, .viewLog: return true
        default: return false
        }
    }

    var title: String {
        switch self {
        case .account: TextsAsset.Preferences.account
        case .general: TextsAsset.Preferences.general
        case .connection: TextsAsset.Preferences.connection
        case .viewLog: TextsAsset.Debug.viewLog
        case .sendLog: TextsAsset.Debug.sendLog
        case .signOut: TextsAsset.Preferences.logout
        }
    }
}

class PreferencesMainViewController: UIViewController {
    var viewModel: PreferencesMainViewModel!, generalViewModel: GeneralViewModelType!, accountViewModel: AccountViewModelType!, connectionsViewModel: ConnectionsViewModelType!, viewLogViewModel: ViewLogViewModel!, helpViewModel: HelpViewModel!, logger: FileLogger!, router: HomeRouter!

    @IBOutlet weak var optionsStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var versionLabel: UILabel!
    
    let generalView: PreferencesGeneralView = PreferencesGeneralView.fromNib()
    let accountView: PreferencesAccountView = PreferencesAccountView.fromNib()
    let connnectionsView: PreferencesConnectionView = PreferencesConnectionView.fromNib()
    let logView: PreferencesViewLogView = PreferencesViewLogView.fromNib()

    private var options: [PreferencesType] = [.general, .account, .connection, .viewLog, .sendLog, .signOut]
    private var selectedRow: Int = 0
    private var optionViews = [PreferencesOptionView]()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        generalView.updateSelection()
        connnectionsView.updateSelection()
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) { }

    private func setup() {
        options.forEach {
            let optionView: PreferencesOptionView = PreferencesOptionView.fromNib()
            optionsStackView.addArrangedSubview(optionView)
            optionView.viewModel = viewModel
            optionView.selectionDelegate = self
            optionView.setup(with: $0)
            optionViews.append(optionView)
        }
        if let firstOption = optionViews.first {
            firstOption.updateSelection(with: true)
        }
        titleLabel.font = UIFont.bold(size: 92)
        versionLabel.font = UIFont.regular(size: 32)
        versionLabel.text = generalViewModel.getVersion()
        createSettingViews()
        accountView.delegate = self
        optionsStackView.addArrangedSubview(UIView())
        bindViews()
    }
    
    private func bindViews() {
        viewModel.currentLanguage.subscribe { _ in
            self.titleLabel.text = TextsAsset.Preferences.title
        }.disposed(by: disposeBag)
    }

    private func createSettingViews() {
        generalView.viewModel = generalViewModel
        generalView.setup()
        addSubview(view: generalView)

        accountView.viewModel = accountViewModel
        accountView.setup()
        addSubview(view: accountView)
        accountView.isHidden = true

        connnectionsView.viewModel = connectionsViewModel
        connnectionsView.setup()
        addSubview(view: connnectionsView)
        connnectionsView.isHidden = true

        logView.setup(with: viewLogViewModel)
        addSubview(view: logView)
        logView.isHidden = true
    }

    private func addSubview(view: UIView) {
        contentStackView.addArrangedSubview(view)
    }

    private func signoutButtonTapped() {
        logger.logD(self, "User tapped to sign out.")
        viewModel.alertManager.showYesNoAlert(viewController: self, title: TextsAsset.Preferences.logout,
                                           message: TextsAsset.Preferences.logOutAlert ,
                                           completion: { result in
            if result {
                self.viewModel?.logoutUser()
            }
        })
    }

    private func sendLogButtonTapped(logView: PreferencesOptionView) {
        if helpViewModel.networkStatus != NetworkStatus.connected {
            logger.logD(self, "No Internet available")
            DispatchQueue.main.async {
                self.helpViewModel.alertManager.showSimpleAlert(viewController: self, title: TextsAsset.appLogSubmitFailAlert, message: "", buttonText: TextsAsset.okay)
            }
        } else {
            logView.updateTitle(with: "\(TextsAsset.Debug.sendingLog)...")
            helpViewModel.submitDebugLog(username: nil) { (_, error) in
                DispatchQueue.main.async {
                    if error == nil {
                        logView.updateTitle()
                    } else {
                        self.helpViewModel.alertManager.showSimpleAlert(viewController: self, title: TextsAsset.appLogSubmitFailAlert, message: "", buttonText: TextsAsset.okay)
                    }
                }
            }
        }
    }

    private func handleCancelAccount() {
        logger.logD(self, "Showing delete account popup.")
        viewModel.alertManager.askPasswordToDeleteAccount(viewController: self).subscribe(onSuccess: { password in
            if let password = password, !password.isEmpty {
                self.accountViewModel.cancelAccount(password: password)
            } else {
                self.logger.logD(self, "Entered password is nil/empty.")
            }
        }, onFailure: { _ in }).disposed(by: disposeBag)
    }
}

extension PreferencesMainViewController: PreferencesOptionViewDelegate {
    func optionWasSelected(_ sender: OptionSelectionView) { }

    func optionWasSelected(with value: PreferencesType, _ sender: PreferencesOptionView) {
        optionViews.forEach {
            $0.updateSelection(with: $0 == sender)
        }
        [generalView, accountView, connnectionsView, logView].forEach {
            if ![PreferencesType.sendLog, PreferencesType.signOut].contains(value) {
                $0.isHidden = true
            }
        }
        switch value {
        case .general: generalView.isHidden = false
        case .account:  accountView.isHidden = false
        case .connection:
            connnectionsView.isHidden = false
//            connnectionsView.updateSelection()
        case .viewLog: logView.isHidden = false
        case .sendLog: sendLogButtonTapped(logView: sender)
        case .signOut: signoutButtonTapped()
        }
    }
}

extension PreferencesMainViewController: PreferencesAccountViewDelegate {
    func actionSelected(with item: AccountItemCell) {
        if item.isUpgradeButton {
            router.routeTo(to: .upgrade(promoCode: nil, pcpID: nil), from: self)
            return
        }
        switch item {
        case .confirmEmail:
            router.routeTo(to: .confirmEmail(delegate: nil), from: self)
        case .cancelAccount:
            handleCancelAccount()
        case .emailEmpty:
            router.routeTo(to: .addEmail, from: self)
        default: return
        }
    }
}

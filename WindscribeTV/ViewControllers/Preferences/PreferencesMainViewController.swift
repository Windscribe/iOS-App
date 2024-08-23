//
//  PreferencesMainViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 01/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

enum PreferencesType: String {
    case general = "General"
    case account = "Account"
    case connection = "Connection"
    case viewLog = "View Debug Log"
    case sendLog = "Send Debug Log"
    case signOut = "Sign Out"

    var isPrimary: Bool {
        switch self {
        case .general, .account, .connection, .viewLog: return true
        default: return false
        }
    }
}

class PreferencesMainViewController: UIViewController {
    var viewModel: PreferencesMainViewModel!, generalViewModel: GeneralViewModelType!, accountViewModel: AccountViewModelType!, connectionsViewModel: ConnectionsViewModelType!, viewLogViewModel: ViewLogViewModel!, helpViewModel: HelpViewModel!, logger: FileLogger!, router: HomeRouter!

    @IBOutlet weak var optionsStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentStackView: UIStackView!

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
            optionView.selectionDelegate = self
            optionView.setup(with: $0)
            optionViews.append(optionView)
        }
        if let firstOption = optionViews.first {
            firstOption.updateSelection(with: true)
        }
        titleLabel.font = UIFont.bold(size: 92)
        createSettingViews()
        accountView.delegate = self
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
        case .connection: connnectionsView.isHidden = false
        case .viewLog: logView.isHidden = false
        case .sendLog: sendLogButtonTapped(logView: sender)
        case .signOut: signoutButtonTapped()
        default: return
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
            router.routeTo(to: .confirmEmail, from: self)
        case .cancelAccount:
            handleCancelAccount()
        }
    }
}

extension PreferencesMainViewController: PreferencesAccountViewDelegate {
    func upgradeWasSelected() {
        router.routeTo(to: .upgrade(promoCode: nil, pcpID: nil), from: self)
    }
}

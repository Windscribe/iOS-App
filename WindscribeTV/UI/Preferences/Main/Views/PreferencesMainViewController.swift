//
//  PreferencesMainViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 01/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

enum PreferencesType {
    case general
    case account
    case connection
    case privacy
    case viewLog
    case sendLog
    case signOut

    var isPrimary: Bool {
        switch self {
        case .general, .account, .connection, .privacy, .viewLog: return true
        default: return false
        }
    }

    var title: String {
        switch self {
        case .account: TextsAsset.Preferences.account
        case .general: TextsAsset.Preferences.general
        case .connection: TextsAsset.Preferences.connection
        case .privacy: TextsAsset.Preferences.privacy
        case .viewLog: TextsAsset.Debug.viewLog
        case .sendLog: TextsAsset.Debug.sendLog
        case .signOut: TextsAsset.Preferences.logout
        }
    }
}

class PreferencesMainViewController: PreferredFocusedViewController {
    var viewModel: PreferencesMainViewModelOld!, generalViewModel: GeneralViewModelType!, accountViewModel: AccountViewModelType!, connectionsViewModel: ConnectionsViewModelType!, viewLogViewModel: ViewLogViewModel!, helpViewModel: SubmitLogViewModel!, logger: FileLogger!, router: HomeRouter!

    @IBOutlet var optionsStackView: UIStackView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentStackView: UIStackView!
    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var loadingView: UIView!
    @IBOutlet var loadingActivityView: UIActivityIndicatorView!

    let generalView: PreferencesGeneralView = .fromNib()
    let accountView: PreferencesAccountView = .fromNib()
    let connnectionsView: PreferencesConnectionView = .fromNib()
    let logView: PreferencesViewLogView = .fromNib()
    let privacyView: PreferencePrivacyView = .fromNib()

    private var options: [PreferencesType] = [.general, .account, .connection, .privacy, .viewLog, .sendLog, .signOut]
    private var selectedRow: Int = 0
    private var optionViews = [PreferencesOptionView]()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Preferences View")
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        generalView.updateSelection()
        connnectionsView.updateSelection()
        logView.scrolltoBottom()

        accountViewModel.loadSession().subscribe(onFailure: { _ in }).disposed(by: disposeBag)
    }

    override func didUpdateFocus(in _: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {}

    private func setup() {
        for option in options {
            let optionView: PreferencesOptionView = PreferencesOptionView.fromNib()
            optionsStackView.addArrangedSubview(optionView)
            optionView.viewModel = viewModel
            optionView.selectionDelegate = self
            optionView.setup(with: option)
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
        setupSwipeRightGesture()
    }

    private func bindViews() {
        viewModel.currentLanguage.subscribe { [weak self] _ in
            guard let self = self else { return }
            self.titleLabel.text = TextsAsset.Preferences.title
        }.disposed(by: disposeBag)

        accountViewModel.cancelAccountState.observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [weak self] state in
            guard let self = self else { return }
            self.logger.logD(self, "Cancel account state: \(state)")
            switch state {
            case .initial:
                self.hideLoading()
            case .loading:
                self.showLoading()
            case let .error(error):
                self.hideLoading()
                self.accountViewModel.alertManager.showSimpleAlert(
                    viewController: self,
                    title: TextsAsset.error,
                    message: error,
                    buttonText: TextsAsset.okay
                )
            case .success:
                self.hideLoading()
                self.accountViewModel.logoutUser()
            }
        }).disposed(by: disposeBag)

        accountViewModel.sessionUpdatedTrigger.subscribe { [weak self] _ in
            guard let self = self else { return }
            self.accountView.setup()
        }.disposed(by: disposeBag)
    }

    private func createSettingViews() {
        generalView.viewModel = generalViewModel
        generalView.setup()
        addSubview(view: generalView)

        accountView.viewModel = accountViewModel
        accountView.setup()
        accountView.bindViews()
        addSubview(view: accountView)
        accountView.isHidden = true

        connnectionsView.viewModel = connectionsViewModel
        connnectionsView.setup()
        addSubview(view: connnectionsView)
        connnectionsView.isHidden = true

        logView.setup(with: viewLogViewModel)
        addSubview(view: logView)
        logView.isHidden = true

        addSubview(view: privacyView)
        privacyView.isHidden = true
    }

    private func addSubview(view: UIView) {
        contentStackView.addArrangedSubview(view)
    }

    private func signoutButtonTapped() {
        logger.logD(self, "User tapped to sign out.")
        viewModel.alertManager.showYesNoAlert(viewController: self, title: TextsAsset.Preferences.logout,
                                              message: TextsAsset.Preferences.logOutAlert,
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
            helpViewModel.submitDebugLog(username: nil) { _, error in
                DispatchQueue.main.async {
                    logView.updateTitle()
                    if error == nil {
                        self.helpViewModel.alertManager.showSimpleAlert(viewController: self, title: TextsAsset.appLogSubmitSuccessAlert, message: "", buttonText: TextsAsset.okay)
                    } else {
                        self.helpViewModel.alertManager.showSimpleAlert(viewController: self, title: TextsAsset.appLogSubmitFailAlert, message: "", buttonText: TextsAsset.okay)
                    }
                }
            }
        }
    }

    private func handleCancelAccount() {
        logger.logD(self, "Showing delete account popup.")
        viewModel.alertManager.askPasswordToDeleteAccount(viewController: self).subscribe(onSuccess: { [weak self] password in
            guard let self = self else { return }
            if let password = password, !password.isEmpty {
                self.accountViewModel.cancelAccount(password: password)
            } else {
                self.logger.logD(self, "Entered password is nil/empty.")
            }
        }, onFailure: { _ in }).disposed(by: disposeBag)
    }

    private func hideLoading() {
        loadingActivityView.stopAnimating()
        loadingView.isHidden = true
    }

    private func showLoading() {
        loadingActivityView.startAnimating()
        loadingView.isHidden = false
    }
}

// MARK: Touches and Keys handling

extension PreferencesMainViewController {
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            super.pressesBegan(presses, with: event)
            if press.type == .rightArrow, updateBodyButtonFocus() {
                break
            }
        }
    }

    private func setupSwipeRightGesture() {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipeRight(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended, updateBodyButtonFocus() { return }
    }

    private func updateBodyButtonFocus() -> Bool {
        let focusedItem = UIScreen.main.focusedView
        for optionView in optionViews {
            if optionView.button == focusedItem, let type = optionView.optionType {
                if !generalView.isHidden {
                    myPreferredFocusedView = generalView.getFocusItem(onTop: [PreferencesType.account, PreferencesType.account].contains(type))
                } else if !accountView.isHidden {
                    myPreferredFocusedView = accountView
                }
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            }
        }
        return false
    }
}

extension PreferencesMainViewController: PreferencesOptionViewDelegate {
    func optionWasSelected(_: OptionSelectionView) {}

    func optionWasSelected(with value: PreferencesType, _ sender: PreferencesOptionView) {
        for optionView in optionViews {
            optionView.updateSelection(with: optionView == sender)
        }
        for item in [generalView, accountView, connnectionsView, privacyView, logView]
            where ![PreferencesType.sendLog, PreferencesType.signOut].contains(value) {
                item.isHidden = true
        }

        logger.logD(self, "Preference of type \(value) selected.")

        switch value {
        case .general: generalView.isHidden = false
        case .account: accountView.isHidden = false
        case .connection:
            connnectionsView.isHidden = false
        case .privacy:
            privacyView.isHidden = false
        case .viewLog: logView.isHidden = false
            logView.scrolltoBottom()
        case .sendLog: sendLogButtonTapped(logView: sender)
        case .signOut: signoutButtonTapped()
        }
    }
}

extension PreferencesMainViewController: PreferencesAccountViewDelegate {
    func actionSelected(with item: AccountItemCell) {
        logger.logD(self, "Account action of type \(item) selected.")
        if item.isUpgradeButton {
            router.routeTo(to: .upgrade(promoCode: nil, pcpID: nil, shouldBeRoot: false), from: self)
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

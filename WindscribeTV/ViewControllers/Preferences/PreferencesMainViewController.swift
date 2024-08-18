//
//  PreferencesMainViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 01/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

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
    var generalViewModel: GeneralViewModelType!, accountViewModel: AccountViewModelType!, connectionsViewModel: ConnectionsViewModelType!, viewLogViewModel: ViewLogViewModel!, logger: FileLogger!

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
            optionView.setup(with: $0)
            optionView.delegate = self
            optionsStackView.addArrangedSubview(optionView)
            optionViews.append(optionView)
        }
        if let firstOption = optionViews.first {
            firstOption.updateSelection(with: true)
        }
        titleLabel.font = UIFont.bold(size: 92)
        createSettingViews()
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
}

extension PreferencesMainViewController: PreferencesOptionViewDelegate {
    func optionWasSelected(with value: PreferencesType) {
        optionViews.forEach {
            $0.updateSelection(with: $0.isType(of: value))
        }
        [generalView, accountView, connnectionsView, logView].forEach { $0.isHidden = true }
        switch value {
        case .general: generalView.isHidden = false
        case .account:  accountView.isHidden = false
        case .connection: connnectionsView.isHidden = false
        case .viewLog: logView.isHidden = false
        default: return
        }
    }
}

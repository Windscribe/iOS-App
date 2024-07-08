//
//	ConnectionModeView.swift
//	Windscribe
//
//	Created by Thomas on 25/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

// MARK: - ConnectionModeView
protocol ConnectionModeViewDelegate: AnyObject {
    func connectionModeViewDidChangeMode(_ option: ConnectionModeType)
    func connectionModeViewDidChangeProtocol(_ value: String)
    func connectionModeViewDidChangePort(_ value: String)
    func connectionModeViewDidSwitch(_ view: ConnectionModeView, value: Bool)
    func connectionModeViewExplain()
}

enum ConnectionHeaderType {
    case `switch`
    case `selection`
}

class ConnectionModeView: UIStackView {
    private(set) var optionMode: ConnectionModeType
    private(set) var listOption: [String]
    private(set) var currentPort: String
    private(set) var listPortOption: [String]
    private(set) var currentProtocol: String
    private(set) var listProtocolOption: [String]
    private(set) var type: ConnectionHeaderType
    private(set) var name: String
    private(set) var footerDescription: String
    private(set) var iconAsset: String
    private(set) var currentSwitchOption: Bool
    weak var delegate: ConnectionModeViewDelegate?

    private var isDarkMode: BehaviorSubject<Bool>
    private let disposeBag = DisposeBag()

    lazy var protocolView: ConnectionModeItemView = {
        let vw = ConnectionModeItemView(isDarkMode: isDarkMode)
        vw.titleLabel.text = TextsAsset.General.protocolType
        vw.dropdownView.setTitle(currentProtocol)
        vw.delegate = self
        vw.addBottomDivider()
        vw.addTopDivider()
        return vw
    }()

    lazy var portView: ConnectionModeItemView = {
        let vw = ConnectionModeItemView(isDarkMode: isDarkMode)
        vw.titleLabel.text = TextsAsset.General.port
        vw.delegate = self
        vw.dropdownView.setTitle(currentPort)
        vw.anchor(height: 48)
        vw.makeRoundCorners(corners: [.bottomLeft, .bottomRight], radius: 6)
        return vw
    }()

    private lazy var mainWrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        return view
    }()

    private lazy var header: SelectableHeaderView = {
        let header = SelectableHeaderView(title: self.name,
                                          imageAsset: self.iconAsset,
                                          optionTitle: optionMode.titleValue,
                                          listOption: listOption,
                                          isDarkMode: isDarkMode)
        header.delegate = self
        header.cornerBottomEdge(false)
        return header
    }()

    private lazy var switchHeader: SwitchHeaderView = {
        let header = SwitchHeaderView(
            title: name,
            icon: iconAsset,
            isDarkMode: isDarkMode)
        header.connectionSecureViewSwitchAction = { [weak self] in
            guard let self = self else { return }
            self.delegate?.connectionModeViewDidSwitch(self, value: header.switchButton.status)
        }
        return header
    }()

    private lazy var footer: FooterView = {
        let view = FooterView(isDarkMode: isDarkMode)
        view.explainTapped = { [weak self] in
            self?.delegate?.connectionModeViewExplain()
        }
        return view
    }()

    init(title: String,
         description: String,
         iconAsset: String,
         optionMode: ConnectionModeType,
         listOption: [String],
         currentProtocol: String,
         listProtocolOption: [String],
         currentPort: String,
         listPortOption: [String],
         isDarkMode: BehaviorSubject<Bool>) {
        self.type = .selection
        self.optionMode = optionMode
        self.listOption = listOption
        self.currentPort = currentPort
        self.currentProtocol = currentProtocol
        self.listPortOption = listPortOption
        self.listProtocolOption = listProtocolOption
        self.name = title
        self.footerDescription = description
        self.iconAsset = iconAsset
        self.currentSwitchOption = false
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        setup()
        bindViews()
    }

    init(title: String,
         description: String,
         iconAsset: String,
         currentSwitchOption: Bool = false,
         currentProtocol: String,
         listProtocolOption: [String],
         currentPort: String,
         listPortOption: [String],
         isDarkMode: BehaviorSubject<Bool>) {
        self.type = .switch
        self.optionMode = .auto
        self.listOption = []
        self.currentPort = currentPort
        self.currentProtocol = currentProtocol
        self.listPortOption = listPortOption
        self.listProtocolOption = listProtocolOption
        self.name = title
        self.footerDescription = description
        self.iconAsset = iconAsset
        self.currentSwitchOption = currentSwitchOption
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func hideShowExpainIcon(_ isHidden: Bool = true) {
        footer.hideShowExplainIcon(isHidden)
    }

    private func bindViews() {
        isDarkMode.subscribe {
            self.mainWrapperView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0).cgColor
        }.disposed(by: disposeBag)
    }

    private func setup() {
        switch type {
        case .switch:
            self.switchHeader.switchButton.status = currentSwitchOption
            addArrangedSubview(switchHeader)
            updateUIForSwitch()
        case .selection:
            addArrangedSubview(header)
            updateUI(optionMode == .manual)
        }
        addArrangedSubviews([
            protocolView,
            portView,
            footer
        ])
        axis = .vertical
        addSubview(mainWrapperView)
        mainWrapperView.fillSuperview()
        mainWrapperView.sendToBack()
        setPadding(UIEdgeInsets(inset: 2))
        update()
        updateCurrentPortOption(currentPort)
        updateCurrentProtocolOption(currentProtocol)
    }

    private func update() {
        footer.content = footerDescription
    }

    func toggleHeader() {
        switchHeader.switchButton.toggle()
        updateUIForSwitch()
    }

    func setSwitchHeaderStatus(_ status: Bool) {
        switchHeader.switchButton.setStatus(status)
        currentSwitchOption = status
        portView.isHidden = !status
        protocolView.isHidden = !status
        updateUIForSwitch()
    }

    func updateListPortOption(_ ports: [String]) {
        self.listPortOption = ports
        if let defaultOption = ports.first {
            self.portView.dropdownView.setTitle(defaultOption)
        }
    }

    func updateCurrentProtocolOption(_ currentProtocol: String) {
        self.protocolView.dropdownView.setTitle(currentProtocol)
    }

    func updateCurrentPortOption(_ currentPort: String) {
        self.portView.dropdownView.setTitle(currentPort)
    }
}

extension ConnectionModeView: SelectableHeaderViewDelegate {
    func selectableHeaderViewDidSelect(_ option: String) {
        let connectionMode = ConnectionModeType(titleValue: option)
        updateUI(connectionMode == .manual)
        delegate?.connectionModeViewDidChangeMode(connectionMode)
    }

    private func updateUI(_ isManual: Bool) {
        protocolView.isHidden = !isManual
        portView.isHidden = !isManual
        header.cornerBottomEdge(!isManual)
    }

    private func updateUIForSwitch() {
        protocolView.isHidden = !currentSwitchOption
        portView.isHidden = !currentSwitchOption
        switchHeader.cornerBottomEdge(!currentSwitchOption)
    }
}

extension ConnectionModeView: DropdownDelegate {
    func optionSelected(dropdown: Dropdown, option: String, relatedIndex: Int) {
        dismissDropdown()
        switch dropdown {
        case portView.dropdownView.dropdown:
            portView.dropdownView.setTitle(option)
            delegate?.connectionModeViewDidChangePort(option)
        case protocolView.dropdownView.dropdown:
            delegate?.connectionModeViewDidChangeProtocol(option)
            protocolView.dropdownView.setTitle(option)
        default:
            break
        }
    }
}

// MARK: - ConnectionModeItemViewDelegate
extension ConnectionModeView: ConnectionModeItemViewDelegate {
    func connectionModeItemViewDidSelectDropdownButton(_ sender: DropdownButton, _ view: ConnectionModeItemView) {
        showDropdown(view)
    }

    private func showDropdown(_ view: ConnectionModeItemView) {
        if currentDropdownView != nil {
            currentDropdownView?.removeWithAnimation()
            currentDropdownView = nil
        }

        if let parentView = self.superview {
            let frameToShowDropDown = self.frame
            let tmpView = UIView(frame: frameToShowDropDown)
            currentDropdownView = Dropdown(attachedView: tmpView)
            currentDropdownView?.dropDownDelegate = self

            switch view {
            case protocolView:
                currentDropdownView?.options = listProtocolOption
                protocolView.dropdownView.dropdown = currentDropdownView
            case portView:
                currentDropdownView?.options = listPortOption
                portView.dropdownView.dropdown = currentDropdownView
            default:
                break
            }

            viewDismiss.addTapGesture(target: self, action: #selector(dismissDropdown))
            parentView.addSubview(viewDismiss)
            viewDismiss.fillSuperview()
            parentView.addSubview(currentDropdownView ?? UIView())
            currentDropdownView?.bringToFront()
        }

    }
}
var currentDropdownView: Dropdown?
let viewDismiss = UIView()

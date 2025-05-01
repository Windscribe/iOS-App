//
//  ConnectedDNSView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/06/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

import RxSwift
import UIKit

// MARK: - ConnectionModeView

protocol ConnectedDNSViewDelegate: AnyObject {
    func connectedDNSViewDidChangeType(_ option: ConnectedDNSType)
    func connectedDNSViewSaveValue(_ value: String)
    func connectedDNSViewExplain()
    func connectedDNSViewDidStartEditing()
}

class ConnectedDNSView: UIStackView {
    private(set) var optionType: ConnectedDNSType
    private(set) var dnsValue: String

    private var isDarkMode: BehaviorSubject<Bool>
    private var isEditMode = BehaviorSubject<Bool>(value: false)
    private let disposeBag = DisposeBag()

    weak var delegate: ConnectedDNSViewDelegate?

    private lazy var header: SelectableHeaderView = {
        let header = SelectableHeaderView(type: GeneralViewType.connectedDNS,
                                          optionTitle: optionType.titleValue,
                                          isDarkMode: isDarkMode)
        return header
    }()

    private lazy var footer: FooterView = {
        let view = FooterView(isDarkMode: isDarkMode)
        view.explainTapped = { [weak self] in
            self?.delegate?.connectedDNSViewExplain()
        }
        view.content = TextsAsset.connectedDNSDescription
        return view
    }()

    private let editButton = ImageButton()
    private let cancelButton = ImageButton()
    private let acceptButton = ImageButton()
    private let valueTextField = UITextField()
    private let dnsValueView = UIStackView()
    private let mainWrapperView = UIView()
    private let editWrapperView = UIView()

    private lazy var editContainerView: UIView = makeContainerView(containing: editButton)
    private lazy var cancelContainerView: UIView = makeContainerView(containing: cancelButton, size: 14)
    private lazy var acceptContainerView: UIView = makeContainerView(containing: acceptButton)

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(optionType: ConnectedDNSType,
         dnsValue: String,
         isDarkMode: BehaviorSubject<Bool>) {
        self.optionType = optionType
        self.dnsValue = dnsValue
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        setup()
        bindViews()
    }

    private func makeContainerView(containing subView: UIView, size: CGFloat = 16) -> UIView {
        let view = UIView()
        view.addSubview(subView)
        subView.translatesAutoresizingMaskIntoConstraints = false
        subView.anchor(left: view.leftAnchor, right: view.rightAnchor,
                       centerY: view.centerYAnchor,
                       paddingLeft: 16,
                       width: size, height: size)
        view.anchor(width: size + 16)
        return view
    }

    private func setup() {
        // Text Field
        valueTextField.translatesAutoresizingMaskIntoConstraints = false
        valueTextField.font = UIFont.text(size: 16)
        valueTextField.text = dnsValue
        valueTextField.layer.opacity = 0.5
        valueTextField.makeHeightAnchor(equalTo: 30)
        valueTextField.autocorrectionType = .no
        valueTextField.spellCheckingType = .no
        valueTextField.keyboardType = .URL
        valueTextField.returnKeyType = .done
        valueTextField.autocapitalizationType = .none

        // Value Container Stack View
        dnsValueView.axis = .horizontal
        dnsValueView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        dnsValueView.isLayoutMarginsRelativeArrangement = true
        dnsValueView.addArrangedSubviews([
            valueTextField,
            editContainerView,
            cancelContainerView,
            acceptContainerView
        ])
        dnsValueView.addSubview(editWrapperView)
        dnsValueView.makeHeightAnchor(equalTo: 48)

        // Accept Button
        acceptButton.setImage(UIImage(named: ImagesAsset.CheckMarkButton.on), for: .normal)

        // Cancel Button
        cancelButton.setImage(UIImage(named: ImagesAsset.closeCross)?.withRenderingMode(.alwaysTemplate), for: .normal)

        // Edit WrappView
        editWrapperView.fillSuperview()
        editWrapperView.sendToBack()
        editWrapperView.addTopDivider()
        editWrapperView.makeRoundCorners(corners: [.bottomLeft, .bottomRight], radius: 6)

        // Header View
        header.delegate = self
        header.cornerBottomEdge(false)

        // Self view
        addArrangedSubviews([header, dnsValueView, footer])
        axis = .vertical
        addSubview(mainWrapperView)
        setPadding(UIEdgeInsets(inset: 2))
        updateUI(optionType == .custom)

        // Main WrappView
        mainWrapperView.fillSuperview()
        mainWrapperView.sendToBack()
        mainWrapperView.translatesAutoresizingMaskIntoConstraints = false
        mainWrapperView.layer.cornerRadius = 8
        mainWrapperView.layer.borderWidth = 2
    }

    private func bindViews() {
        // Darm Mode Binding
        isDarkMode.subscribe {
            self.editButton.setImage(ThemeUtils.editImage(isDarkMode: $0), for: .normal)
            self.cancelButton.tintColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.valueTextField.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.valueTextField.attributedPlaceholder = NSAttributedString(string: TextsAsset.connectedDNSValueFieldDescription, attributes: [NSAttributedString.Key.foregroundColor: ThemeUtils.primaryTextColor50(isDarkMode: $0)])
            self.mainWrapperView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0).cgColor
            self.editWrapperView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
        }.disposed(by: disposeBag)

        // Button edit tap binding
        editButton.rx.tap.bind { _ in
            self.isEditMode.onNext(true)
            self.valueTextField.becomeFirstResponder()
            self.delegate?.connectedDNSViewDidStartEditing()
        }.disposed(by: disposeBag)

        // Button edit tap binding
        cancelButton.rx.tap.bind { _ in
            self.valueTextField.text = self.dnsValue
            self.valueTextField.resignFirstResponder()
            self.isEditMode.onNext(false)
        }.disposed(by: disposeBag)

        // Accept button tap binding
        acceptButton.rx.tap.bind { _ in
            self.submitValue()
        }.disposed(by: disposeBag)

        // Edit Mode binding
        isEditMode.subscribe {
            self.editContainerView.isHidden = $0
            self.valueTextField.isHidden = false
            self.cancelContainerView.isHidden = !$0
            self.acceptContainerView.isHidden = !$0
        }.disposed(by: disposeBag)

        valueTextField.rx.controlEvent(.editingDidEndOnExit).subscribe { _ in
            self.submitValue()
        }.disposed(by: disposeBag)
        valueTextField.rx.controlEvent(.editingDidBegin).subscribe { _ in
            self.isEditMode.onNext(true)
            self.delegate?.connectedDNSViewDidStartEditing()
        }.disposed(by: disposeBag)
    }

    func shouldHideTextfield(isEditMode: Bool) -> Bool {
        if dnsValue.isEmpty {
            return false
        }
        return !isEditMode
    }

    func updateConnectedDNSValue(value: String) {
        dnsValue = value
        valueTextField.text = dnsValue
        isEditMode.onNext(false)
        valueTextField.resignFirstResponder()
    }

    func cancelUpdateValue() {
        updateConnectedDNSValue(value: dnsValue)
    }

    private func submitValue() {
        guard let text = valueTextField.text else { return }
        delegate?.connectedDNSViewSaveValue(text)
    }
}

extension ConnectedDNSView: SelectableHeaderViewDelegate {
    func selectableHeaderViewDidSelect(_ option: String) {
        let connectedDNS = ConnectedDNSType(titleValue: option)
        updateUI(connectedDNS == .custom)
        delegate?.connectedDNSViewDidChangeType(connectedDNS)
    }

    private func updateUI(_ isCustom: Bool) {
        dnsValueView.isHidden = !isCustom
        header.cornerBottomEdge(!isCustom)
    }
}

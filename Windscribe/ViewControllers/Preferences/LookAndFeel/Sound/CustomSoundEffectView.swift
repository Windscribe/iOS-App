//
//  CustomSoundEffectView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-15.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

protocol CustomSoundEffectViewDelegate: AnyObject {
    func customSoundDidChangeType(_ domain: SoundAssetDomainType, type: SoundEffectType)
    func customSoundDidPickCustomFile(domain: SoundAssetDomainType, path: String)
}

class CustomSoundEffectView: UIView {
    weak var delegate: CustomSoundEffectViewDelegate?

    private let isDarkMode: BehaviorSubject<Bool>
    private let disposeBag = DisposeBag()

    private let mainEffectOptions = [
        TextsAsset.General.none,
        TextsAsset.General.bundled,
        TextsAsset.General.custom
    ]

    private var connectCurrentType: SoundEffectType
    private var disconnectCurrentType: SoundEffectType
    private var activeDropdownDomain: SoundAssetDomainType?

    // UI
    private let mainWrapperView = UIView()
    private let containerStack = UIStackView()
    private let contentWrapperView = UIStackView()

    private let connectWrapperView = UIView()
    private let connectSubtypeWrapperView = UIView()
    private let connectValueLabel = UILabel()
    private let connectSubtypeValueLabel = UILabel()
    private let connectCustomWrapperView = UIView()
    private let connectCustomValueLabel = UILabel()

    private let disconnectWrapperView = UIView()
    private let disconnectSubtypeWrapperView = UIView()
    private let disconnectValueLabel = UILabel()
    private let disconnectSubtypeValueLabel = UILabel()
    private let disconnectCustomWrapperView = UIView()
    private let disconnectCustomValueLabel = UILabel()

    private let footerView: FooterView

    private lazy var header = SelectableHeaderView(
        title: LookAndFeelHelper.getTitle(.soundNotification),
        imageAsset: LookAndFeelHelper.getAsset(.soundNotification),
        isDarkMode: isDarkMode
    ).then {
        $0.disableDropdown()
        $0.hideDropdownIcon()
        $0.cornerBottomEdge(false)
        $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    private let borderWrapperView = UIView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.layer.cornerRadius = 6
        $0.clipsToBounds = true
    }

    private let borderView = UIView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 2
    }

    init(isDarkMode: BehaviorSubject<Bool>,
         connectInitialType: SoundEffectType,
         disconnectInitialType: SoundEffectType) {
        self.isDarkMode = isDarkMode

        connectCurrentType = connectInitialType
        disconnectCurrentType = disconnectInitialType
        footerView = FooterView(isDarkMode: isDarkMode)

        super.init(frame: .zero)

        setupView()
        bindTheme()
        updateViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Main Wrapper
        addSubview(mainWrapperView)
        mainWrapperView.do {
            $0.fillSuperview()
            $0.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
        }

        // Border
        addSubview(borderView)
        borderView.fillSuperview()
        borderView.sendToBack()

        addSubview(borderWrapperView)
        borderWrapperView.fillSuperview(padding: UIEdgeInsets(inset: 2))

        borderWrapperView.addSubview(mainWrapperView)
        mainWrapperView.fillSuperview()

        containerStack.do {
            $0.axis = .vertical
            $0.spacing = 0
        }

        let mask = UIView().then {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        mainWrapperView.addSubview(mask)
        mask.do {
            $0.fillSuperview()
            $0.layer.cornerRadius = 4
            $0.layer.masksToBounds = true
            $0.addSubview(containerStack)
        }

        containerStack.fillSuperview()

        contentWrapperView.do {
            $0.axis = .vertical
            $0.spacing = 0
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 8
            $0.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
        }

        // Connected
        containerStack.addArrangedSubview(contentWrapperView)
        contentWrapperView.addArrangedSubviews([header, makeInsetDivider()])

        setupRow(container: connectWrapperView,
                 title: "When Connected",
                 valueLabel: connectValueLabel,
                 selector: #selector(tapConnected))
        contentWrapperView.addArrangedSubview(connectWrapperView)
        setupSubtypeValueRow(container: connectSubtypeWrapperView,
                             valueLabel: connectSubtypeValueLabel,
                             selector: #selector(tapConnectedSubtype))
        setupCustomValueRow(container: connectCustomWrapperView,
                            valueLabel: connectCustomValueLabel,
                            selector: #selector(tapConnectedCustom))
        contentWrapperView.do {
            $0.addArrangedSubview(connectSubtypeWrapperView)
            $0.addArrangedSubview(connectCustomWrapperView)
            $0.addArrangedSubview(makeInsetDivider())
        }

        // Disconnected
        setupRow(container: disconnectWrapperView,
                 title: "When Disconnected",
                 valueLabel: disconnectValueLabel,
                 selector: #selector(tapDisconnected))
        contentWrapperView.addArrangedSubview(disconnectWrapperView)
        setupSubtypeValueRow(container: disconnectSubtypeWrapperView,
                             valueLabel: disconnectSubtypeValueLabel,
                             selector: #selector(tapDisconnectedSubtype))
        setupCustomValueRow(container: disconnectCustomWrapperView,
                            valueLabel: disconnectCustomValueLabel,
                            selector: #selector(tapDisconnectedCustom))

        contentWrapperView.do {
            $0.addArrangedSubview(disconnectSubtypeWrapperView)
            $0.addArrangedSubview(disconnectCustomWrapperView)
        }

        // Footer
        footerView.do {
            $0.content = LookAndFeelHelper.getDescription(.soundNotification)
            $0.hideShowExplainIcon(true)
        }
        containerStack.addArrangedSubview(footerView)
    }

    private func setupRow(container: UIView, title: String, valueLabel: UILabel, selector: Selector) {
        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = .text(size: 16)
        }

        valueLabel.do {
            $0.font = .text(size: 16)
            $0.layer.opacity = 0.5
        }

        let icon = UIImageView().then {
            $0.image = ThemeUtils.dropDownIcon(isDarkMode: (try? isDarkMode.value()) ?? true)
            $0.contentMode = .scaleAspectFit
            $0.anchor(width: 16, height: 16)
        }

        let tapZone = UIStackView(arrangedSubviews: [valueLabel, icon]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.isUserInteractionEnabled = true
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: selector))
        }

        let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), tapZone]).then {
            $0.axis = .horizontal
            $0.setPadding(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
            $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }

        container.do {
            $0.backgroundColor = .clear
            $0.addSubview(row)
        }
        row.fillSuperview()
    }

    private func setupSubtypeValueRow(container: UIView, valueLabel: UILabel, selector: Selector) {
        let icon = UIImageView().then {
            $0.image = ThemeUtils.dropDownIcon(isDarkMode: (try? isDarkMode.value()) ?? true)
            $0.contentMode = .scaleAspectFit
            $0.anchor(width: 16, height: 16)
        }

        valueLabel.do {
            $0.font = .text(size: 16)
            $0.layer.opacity = 0.5
        }

        let tapZone = UIStackView(arrangedSubviews: [valueLabel, icon]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.isUserInteractionEnabled = true
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: selector))
        }

        let row = UIStackView(arrangedSubviews: [tapZone, UIView()]).then {
            $0.axis = .horizontal
            $0.setPadding(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }

        container.do {
            $0.backgroundColor = .clear
            $0.isHidden = true
            $0.addSubview(row)
        }

        row.fillSuperview()
    }

    private func setupCustomValueRow(container: UIView, valueLabel: UILabel, selector: Selector) {
        let editIcon = UIImageView().then {
            $0.image = UIImage(systemName: "pencil")?.withRenderingMode(.alwaysTemplate)
            $0.tintColor = ThemeUtils.primaryTextColor(isDarkMode: (try? isDarkMode.value()) ?? true)
            $0.contentMode = .scaleAspectFit
            $0.anchor(width: 14, height: 14)
        }

        valueLabel.do {
            $0.font = .text(size: 16)
            $0.layer.opacity = 0.5
        }

        let tapZone = UIStackView(arrangedSubviews: [valueLabel, editIcon]).then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.isUserInteractionEnabled = true
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: selector))
        }

        let row = UIStackView(arrangedSubviews: [tapZone, UIView()]).then {
            $0.axis = .horizontal
            $0.setPadding(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }

        container.do {
            $0.backgroundColor = .clear
            $0.isHidden = true
            $0.addSubview(row)
        }

        row.fillSuperview()
    }

    private func bindTheme() {
        isDarkMode.subscribe(onNext: { [weak self] isDark in
            guard let self = self else { return }

            self.header.changeThemeColor(.clear)
            self.borderView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark).cgColor
            self.contentWrapperView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark)
            self.footerView.backgroundColor = .clear

            [connectValueLabel, disconnectValueLabel,
             connectSubtypeValueLabel, disconnectSubtypeValueLabel].forEach {
                $0.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            }

        }).disposed(by: disposeBag)
    }

    private func makeInsetDivider() -> UIView {
        let divider = UIView.divider(color: nil, height: 2)

        let wrapper = UIStackView(arrangedSubviews: [divider]).then {
            $0.axis = .horizontal
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        }

        return wrapper
    }

    private func updateViews() {
        connectValueLabel.text = connectCurrentType.mainCategory
        disconnectValueLabel.text = disconnectCurrentType.mainCategory

        connectSubtypeWrapperView.isHidden = connectCurrentType.bundledSubtype == nil
        disconnectSubtypeWrapperView.isHidden = disconnectCurrentType.bundledSubtype == nil

        connectSubtypeValueLabel.text = connectCurrentType.bundledSubtype?.displayName
        disconnectSubtypeValueLabel.text = disconnectCurrentType.bundledSubtype?.displayName

        connectCustomWrapperView.isHidden = connectCurrentType != .custom
        disconnectCustomWrapperView.isHidden = disconnectCurrentType != .custom

        connectCustomValueLabel.text = "[no selection]"
        disconnectCustomValueLabel.text = "[no selection]"
    }

    // MARK: Actions

    @objc private func tapConnected() {
        activeDropdownDomain = .connect
        showDropdown(attachedTo: connectWrapperView)
    }

    @objc private func tapDisconnected() {
        activeDropdownDomain = .disconnect
        showDropdown(attachedTo: disconnectWrapperView)
    }

    @objc private func tapConnectedSubtype() {
        activeDropdownDomain = .connect
        showSubtypeDropdown(attachedTo: connectSubtypeWrapperView)
    }

    @objc private func tapDisconnectedSubtype() {
        activeDropdownDomain = .disconnect
        showSubtypeDropdown(attachedTo: disconnectSubtypeWrapperView)
    }

    @objc private func tapConnectedCustom() {
        activeDropdownDomain = .connect
        presentFilePicker()
    }

    @objc private func tapDisconnectedCustom() {
        activeDropdownDomain = .disconnect
        presentFilePicker()
    }
}

// MARK: Dropdown Interface

extension CustomSoundEffectView: DropdownDelegate {

    private func showDropdown(attachedTo view: UIView) {
        let convertedFrame = view.convert(view.bounds, to: window)
        let tmpView = UIView(frame: CGRect(
            x: convertedFrame.maxX - 124 - 16,
            y: convertedFrame.minY + 16,
            width: 124,
            height: 0
        ))

        createDropDown(using: tmpView, with: mainEffectOptions)
    }

    private func showSubtypeDropdown(attachedTo view: UIView) {
        let convertedFrame = view.convert(view.bounds, to: window)
        let tmpView = UIView(frame: CGRect(
            x: convertedFrame.minX + 16,
            y: convertedFrame.minY + 8,
            width: 124,
            height: 0
        ))

        let subtypeOptions = SoundEffectSubtype.allCases.map { $0.displayName }

        createDropDown(using: tmpView, with: subtypeOptions)
    }

    private func createDropDown(using tempView: UIView, with options: [String]) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first else { return }

        currentDropdownView?.removeWithAnimation()
        currentDropdownView = nil

        let dropdown = Dropdown(attachedView: tempView).then {
            $0.dropDownDelegate = self
            $0.options = options
        }

        viewDismiss.addTapGesture(target: self, action: #selector(hideDropdownView))
        window.addSubview(viewDismiss)
        viewDismiss.fillSuperview()

        window.addSubview(dropdown)
        dropdown.bringToFront()
        currentDropdownView = dropdown
    }

    @objc private func hideDropdownView() {
        viewDismiss.removeFromSuperview()
        currentDropdownView?.removeWithAnimation()
        currentDropdownView = nil
    }

    func optionSelected(dropdown: Dropdown, option: String, relatedIndex: Int) {
        hideDropdownView()

        guard let domain = activeDropdownDomain else {
            return
        }

        if dropdown.options == mainEffectOptions {
            let type = SoundEffectType(mainCategory: option)

            switch domain {
            case .connect:
                connectCurrentType = type
            case .disconnect:
                disconnectCurrentType = type
            }
        } else {
            guard let subtype = SoundEffectSubtype(rawValue: option) else {
                return
            }

            switch domain {
            case .connect:
                connectCurrentType = .bundled(subtype: subtype)
            case .disconnect:
                disconnectCurrentType = .bundled(subtype: subtype)
            }
        }

        updateViews()

        delegate?.customSoundDidChangeType(
            domain,
            type: domain == .connect ? connectCurrentType : disconnectCurrentType)
    }
}

extension CustomSoundEffectView: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }

        // Optional: validate it's an audio file, or trust picker config

        let fileName = selectedURL.lastPathComponent
        let filePath = selectedURL.path

        let domain = activeDropdownDomain ?? .connect // fallback

        switch domain {
        case .connect:
            connectCustomValueLabel.text = fileName
        case .disconnect:
            disconnectCustomValueLabel.text = fileName
        }

        delegate?.customSoundDidPickCustomFile(domain: domain, path: filePath)
    }

    private func presentFilePicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        picker.delegate = self
        picker.allowsMultipleSelection = false

        if let vc = self.parentViewController {
            vc.present(picker, animated: true, completion: nil)
        }
    }
}

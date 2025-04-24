//
//  SelectableHeaderView.swift
//  Windscribe
//
//  Created by Thomas on 22/07/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

protocol SelectableHeaderViewDelegate: AnyObject {
    func selectableHeaderViewDidSelect(_ option: String)
}

class SelectableHeaderView: UIStackView {
    private(set) var type: SelectionViewType
    private(set) var currentOption: String
    private(set) var systemImageUsed: Bool

    var viewToAddDropdown: UIView?

    weak var delegate: SelectableHeaderViewDelegate?
    private let disposeBag = DisposeBag()

    private lazy var titleLabel = UILabel().then {
        $0.font = UIFont.bold(size: 16)
        $0.text = type.title
        $0.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
    }

    private lazy var actionImage = UIImageView().then {
        $0.anchor(width: 16, height: 16)
        $0.contentMode = .scaleAspectFit
        $0.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
    }

    private lazy var optionLabel = UILabel().then {
        $0.setTextWithOffSet(text: currentOption)
        $0.font = UIFont.text(size: 16)
        $0.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        $0.layer.opacity = 0.5
    }

    private lazy var dropdownView = UIStackView().then {
        $0.addArrangedSubviews([optionLabel, actionImage])
        $0.axis = .horizontal
        $0.spacing = 8
        $0.isUserInteractionEnabled = true
        $0.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDropdown)))
    }

    private lazy var iconImage = UIImageView().then {
        $0.image = UIImage(named: type.asset)
        $0.contentMode = .scaleAspectFit
        $0.anchor(width: 18, height: 18)
        $0.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
    }

    private lazy var wrapperView = UIView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
    }

    init(viewToAddDropdown: UIView? = nil, type: SelectionViewType, optionTitle: String = "", listOption: [String] = [], systemImageUsed: Bool = false, isDarkMode: BehaviorSubject<Bool>) {
         self.type = type
        currentOption = optionTitle
        self.viewToAddDropdown = viewToAddDropdown
        self.systemImageUsed = systemImageUsed
        super.init(frame: .zero)
        setup()
        bindViews(isDarkMode: isDarkMode)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.titleLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.actionImage.setImageColor(color: ThemeUtils.primaryTextColor50(isDarkMode: $0))
            self.optionLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.wrapperView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
            if iconImage.image == nil {
                self.iconImage.layer.borderColor = ThemeUtils.primaryTextColor(isDarkMode: $0).cgColor
            } else {
                self.iconImage.updateTheme(isDark: $0)
            }
        }).disposed(by: disposeBag)
    }

    private func setup() {
        addArrangedSubviews([
            iconImage,
            titleLabel,
            UIView(),
            dropdownView
        ])
        spacing = 16
        axis = .horizontal
        setPadding(UIEdgeInsets(inset: 16))
        addSubview(wrapperView)
        wrapperView.fillSuperview()
        wrapperView.sendToBack()
        clipsToBounds = true
        cornerBottomEdge(true)

        actionImage.image = UIImage(named: type.type == .selection ?
                                    ImagesAsset.DarkMode.dropDownIcon :
                                        ImagesAsset.serverWhiteRightArrow)?
            .withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
    }

    func cornerBottomEdge(_ haveCorner: Bool) {
        wrapperView.layer.mask = nil
        if !haveCorner {
            wrapperView.makeRoundCorners(corners: [.topLeft, .topRight], radius: 6)
        } else {
            wrapperView.makeRoundCorners(corners: [.topLeft, .topRight, .bottomRight, .bottomLeft], radius: 6)
        }
    }

    func changeThemeColor(_ color: UIColor) {
        wrapperView.backgroundColor = color
    }

    func disableDropdown() {
        dropdownView.isUserInteractionEnabled = false
    }

    func hideDropdownIcon() {
        actionImage.isHidden = true
    }

    func refreshLocalization(optionTitle: String) {
        currentOption = optionTitle
        titleLabel.setTextWithOffSet(text: type.title)
        optionLabel.setTextWithOffSet(text: currentOption)
    }
}

extension SelectableHeaderView {
    @objc private func showDropdown() {
        if currentDropdownView != nil {
            currentDropdownView?.removeWithAnimation()
            currentDropdownView = nil
        }

        if let parentView = superview, let grandParentView = parentView.superview {
            let frameToShowDropDown = parentView.frame
            let displayFrame = CGRect(x: frameToShowDropDown.origin.x - 16,
                                      y: frameToShowDropDown.origin.y + 16,
                                      width: frameToShowDropDown.width,
                                      height: frameToShowDropDown.height)
            let tmpView = UIView(frame: displayFrame)
            currentDropdownView = Dropdown(attachedView: tmpView)
            currentDropdownView?.dropDownDelegate = self
            currentDropdownView?.options = type.listOption
            viewDismiss.addTapGesture(target: self, action: #selector(dismissDropdown))
            grandParentView.addSubview(viewDismiss)
            viewDismiss.fillSuperview()
            grandParentView.addSubview(currentDropdownView ?? UIView())
            currentDropdownView?.bringToFront()
        }
    }
}

extension SelectableHeaderView: DropdownDelegate {
    func optionSelected(dropdown _: Dropdown, option: String, relatedIndex _: Int) {
        if currentDropdownView != nil {
            currentDropdownView?.removeWithAnimation()
            currentDropdownView = nil
        }
        dismissDropdown()
        optionLabel.setTextWithOffSet(text: option)
        delegate?.selectableHeaderViewDidSelect(option)
    }
}

extension UIView {
    @objc func dismissDropdown() {
        viewDismiss.removeFromSuperview()
        if currentDropdownView != nil {
            currentDropdownView?.removeWithAnimation()
            currentDropdownView = nil
        }
    }
}

extension UIViewController {
    @objc func dismissDropdown() {
        viewDismiss.removeFromSuperview()
        if currentDropdownView != nil {
            currentDropdownView?.removeWithAnimation()
            currentDropdownView = nil
        }
    }
}

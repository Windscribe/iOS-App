//
//  SelectableHeaderView.swift
//  Windscribe
//
//  Created by Thomas on 22/07/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

protocol SelectableHeaderViewDelegate: AnyObject {
    func selectableHeaderViewDidSelect(_ option: String)
}

class SelectableHeaderView: UIStackView {
    private(set) var title: String
    private(set) var currentOption: String
    private(set) var listOption: [String]
    private(set) var imageAsset: String?
    var viewToAddDropdown: UIView?

    weak var delegate: SelectableHeaderViewDelegate?
    private let disposeBag = DisposeBag()

    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.bold(size: 16)
        lbl.text = title
        lbl.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        return lbl
    }()

    private lazy var iconDropdown: UIImageView = {
        let imv = UIImageView()
        imv.anchor(width: 16, height: 16)
        imv.contentMode = .scaleAspectFit
        imv.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        return imv
    }()

    private lazy var optionLabel: UILabel = {
        let lbl = UILabel()
        lbl.setTextWithOffSet(text: currentOption)
        lbl.font = UIFont.text(size: 16)
        lbl.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        lbl.layer.opacity = 0.5
        return lbl
    }()

    private lazy var dropdownView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            optionLabel, iconDropdown
        ])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.isUserInteractionEnabled = true
        stack.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        stack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDropdown)))
        return stack
    }()

    private lazy var iconImage: UIImageView = {
        let imageView = UIImageView()
        if let imageAsset = imageAsset {
            imageView.image = UIImage(named: imageAsset)
        } else {
            imageView.layer.cornerRadius = 4
            imageView.layer.borderWidth = 2
        }
        imageView.contentMode = .scaleAspectFit
        imageView.anchor(width: 18, height: 18)
        imageView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        return imageView
    }()

    private lazy var wrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()

    init(viewToAddDropdown: UIView? = nil, title: String, imageAsset: String?, optionTitle: String, listOption: [String], isDarkMode: BehaviorSubject<Bool>) {
        self.title = title
        self.imageAsset = imageAsset
        self.currentOption = optionTitle
        self.listOption = listOption
        self.viewToAddDropdown = viewToAddDropdown
        super.init(frame: .zero)
        setup()
        bindViews(isDarkMode: isDarkMode)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.titleLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.iconDropdown.image = ThemeUtils.dropDownIcon(isDarkMode: $0)
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
    }

    func cornerBottomEdge(_ haveCorner: Bool) {
        wrapperView.layer.mask = nil
        if !haveCorner {
            wrapperView.makeRoundCorners(corners: [.topLeft, .topRight], radius: 6)
        } else {
            wrapperView.makeRoundCorners(corners: [.topLeft, .topRight, .bottomRight,.bottomLeft], radius: 6)
        }

    }

    func disableDropdown() {
        dropdownView.isUserInteractionEnabled = false
    }
    func hideDropdownIcon() {
        iconDropdown.isHidden = true
    }

    func updateStringData(title: String, optionTitle: String, listOption: [String]) {
        self.title = title
        self.currentOption = optionTitle
        self.listOption = listOption

        self.titleLabel.setTextWithOffSet(text: title)
        self.optionLabel.setTextWithOffSet(text: currentOption)
    }
}

extension SelectableHeaderView {
    @objc private func showDropdown() {
        if currentDropdownView != nil {
            currentDropdownView?.removeWithAnimation()
            currentDropdownView = nil
        }

        if let parentView = self.superview,
           let grandParentView = parentView.superview {
            let frameToShowDropDown = parentView.frame
            let displayFrame = CGRect(x: frameToShowDropDown.origin.x - 16,
                                      y: frameToShowDropDown.origin.y + 16,
                                      width: frameToShowDropDown.width,
                                      height: frameToShowDropDown.height)
            let tmpView = UIView(frame: displayFrame)
            currentDropdownView = Dropdown(attachedView: tmpView)
            currentDropdownView?.dropDownDelegate = self
            currentDropdownView?.options = listOption
            viewDismiss.addTapGesture(target: self, action: #selector(dismissDropdown))
            grandParentView.addSubview(viewDismiss)
            viewDismiss.fillSuperview()
            grandParentView.addSubview(currentDropdownView ?? UIView())
            currentDropdownView?.bringToFront()
        }
    }
}

extension SelectableHeaderView: DropdownDelegate {
    func optionSelected(dropdown: Dropdown, option: String, relatedIndex: Int) {
        if currentDropdownView != nil {
            currentDropdownView?.removeWithAnimation()
            currentDropdownView = nil
        }
        dismissDropdown()
        self.optionLabel.setTextWithOffSet(text: option)
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

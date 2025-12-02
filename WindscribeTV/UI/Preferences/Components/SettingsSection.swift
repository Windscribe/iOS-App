//
//  SettingsSection.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 02/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol SettingsSectionDelegate: AnyObject {
    func optionWasSelected(for view: SettingsSection, with value: String)
}

class SettingsSection: UIView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentStackView: UIStackView!
    @IBOutlet var tempView: UIView!
    @IBOutlet var scrollView: UIScrollView!

    @IBOutlet var contentViewTop: NSLayoutConstraint!

    private var listOfOptions = [String]()
    private var listOfOptionViewss = [SettingOption]()

    weak var delegate: SettingsSectionDelegate?

    func populate(with list: [String], title: String? = nil) {
        listOfOptions = list
        updateTitle(with: title)
        contentStackView.removeAllArrangedSubviews()
        listOfOptionViewss = [SettingOption]()
        for item in list {
            let optionView: SettingOption = SettingOption.fromNib()
            optionView.setup(with: item)
            optionView.delegate = self
            contentStackView.addArrangedSubview(optionView)
            listOfOptionViewss.append(optionView)
        }
        contentStackView.addArrangedSubview(UIView())
        contentStackView.layoutIfNeeded()
        scrollView.layoutIfNeeded()
    }

    private func updateTitle(with text: String?) {
        if let title = text {
            titleLabel.attributedText = NSAttributedString(string: title.uppercased(),
                                                           attributes: [
                                                               .font: UIFont.bold(size: 32),
                                                               .foregroundColor: UIColor.white.withAlphaComponent(0.2),
                                                               .kern: 4
                                                           ])
            contentViewTop.constant = 24
        } else {
            contentViewTop.constant = 0
            titleLabel.isHidden = true
        }
        layoutIfNeeded()
    }

    func updateText(with list: [String], title: String? = nil) {
        updateTitle(with: title)
        listOfOptions = list
        for (index, text) in list.enumerated() {
            listOfOptionViewss[index].updateTitle(with: text)
        }
    }

    func select(option: String, animated: Bool = true) {
        for arrangedSubview in contentStackView.arrangedSubviews {
            if let optionView = arrangedSubview as? SettingOption {
                optionView.updateSelection(with: false)
            }
        }

        if let index = listOfOptions.firstIndex(of: option) {
            if let optionView = contentStackView.arrangedSubviews[index] as? SettingOption {
                optionView.updateSelection(with: true)
                scrollView.delegate = self
                scrollToView(view: optionView, index: index, animated: animated)
            }
        }
    }

    private func scrollToView(view: UIView, index _: Int, animated: Bool) {
        let originX = contentStackView.convert(view.frame.origin, to: scrollView).x
        scrollView.scrollRectToVisible(CGRect(x: originX, y: 0, width: view.frame.width, height: 1), animated: animated)
    }
}

extension SettingsSection: UIScrollViewDelegate {}

extension SettingsSection: SettingOptionDelegate {
    func optionWasSelected(with value: String) {
        select(option: value)
        delegate?.optionWasSelected(for: self, with: value)
    }
}

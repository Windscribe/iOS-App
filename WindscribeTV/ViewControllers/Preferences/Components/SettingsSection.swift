//
//  SettingsSection.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 02/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

protocol SettingsSectionDelegate: NSObject {
    func optionWasSelected(for view: SettingsSection, with value: String)
}

class SettingsSection: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var tempView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var contentViewTop: NSLayoutConstraint!

    private var listOfOptions = [String]()
    private var listOfOptionViewss = [SettingOption]()

    weak var delegate: SettingsSectionDelegate?

    func populate(with list: [String], title: String? = nil) {
        listOfOptions = list
        if let title = title {
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
        self.layoutIfNeeded()

        contentStackView.removeAllArrangedSubviews()
        list.forEach {
            let optionView: SettingOption = SettingOption.fromNib()
            optionView.setup(with: $0)
            optionView.delegate = self
            contentStackView.addArrangedSubview(optionView)
            listOfOptionViewss.append(optionView)
        }
        contentStackView.addArrangedSubview(UIView())
        contentStackView.layoutIfNeeded()
        scrollView.layoutIfNeeded()
    }

    func updateText(with list: [String], title: String? = nil) {
        list.enumerated().forEach { (index, text) in
            listOfOptionViewss[index].titleLabel.text = text
        }
    }

    func select(option: String, animated: Bool = true) {
        contentStackView.arrangedSubviews.forEach {
            if let optionView = $0 as? SettingOption {
                optionView.updateSelection(with: false)
            }
        }

        if let index = listOfOptions.firstIndex(of: option),
        let optionView = contentStackView.arrangedSubviews[index] as? SettingOption {
            optionView.updateSelection(with: true)
            scrollView.delegate = self
            scrollToView(view: optionView, index: index, animated: animated)
        }
    }

    private func scrollToView(view: UIView, index: Int, animated: Bool) {
        let originX = contentStackView.convert(view.frame.origin, to: scrollView).x
        scrollView.scrollRectToVisible(CGRect(x: originX, y: 0 , width: view.frame.width, height: 1), animated: animated)
    }
}

extension SettingsSection: UIScrollViewDelegate {

}

extension SettingsSection: SettingOptionDelegate {
    func optionWasSelected(with value: String) {
        select(option: value)
        delegate?.optionWasSelected(for: self, with: value)
    }
}

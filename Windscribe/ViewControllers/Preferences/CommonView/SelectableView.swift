//
//  SelectableView.swift
//  Windscribe
//
//  Created by Thomas on 27/07/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

enum SelectableViewType {
    case selection
    case direction
    case directionWithoutIcon
}

protocol SelectableViewDelegate: AnyObject {
    func selectableViewSelect(_ sender: SelectableView, option: String)
    func selectableViewDirection(_ sender: SelectableView)
}

class SelectableView: UIStackView {
    private(set) var header: String
    private(set) var currentOption: String
    private(set) var listOption: [String]
    private(set) var type: SelectableViewType
    private(set) var subTitle: String?
    private(set) var iconAsset: String?

    weak var delegate: SelectableViewDelegate?

    private let isDarkMode: BehaviorSubject<Bool>
    private let disposeBag = DisposeBag()

    private lazy var mainWrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        return view
    }()

    private lazy var headerView: SelectableHeaderView = {
        let header = SelectableHeaderView(title: header,
                                          imageAsset: iconAsset,
                                          optionTitle: currentOption,
                                          listOption: listOption,
                                          isDarkMode: isDarkMode)
        switch type {
        case .selection:
            header.delegate = self
        case .direction:
            header.disableDropdown()
            header.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(headerTapAction)))
        case .directionWithoutIcon:
            header.disableDropdown()
            header.hideDropdownIcon()
            header.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(headerTapAction)))
        }

        return header
    }()

    private lazy var footer = FooterView(isDarkMode: isDarkMode)

    init(type: SelectableViewType = .selection,
         header: String,
         currentOption: String,
         listOption: [String],
         icon: String?,
         isDarkMode: BehaviorSubject<Bool>,
         subTitle: String? = nil,
         delegate: SelectableViewDelegate? = nil) {
        self.header = header
        self.currentOption = currentOption
        self.listOption = listOption
        self.subTitle = subTitle
        iconAsset = icon
        self.type = type
        self.delegate = delegate
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        setup()
        bindViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindViews() {
        isDarkMode.subscribe {
            self.updateTheme(isDark: $0)
        }.disposed(by: disposeBag)
    }

    private func setup() {
        addArrangedSubviews([
            headerView,
            footer
        ])
        setPadding(UIEdgeInsets(inset: 2))
        axis = .vertical
        addSubview(mainWrapperView)
        mainWrapperView.fillSuperview()
        mainWrapperView.sendToBack()
        footer.content = subTitle ?? "Explain me!".localize()
    }

    private func update() {}

    func hideShowExplainIcon(_ isHidden: Bool = true) {
        footer.hideShowExplainIcon(isHidden)
    }

    @objc private func headerTapAction() {
        delegate?.selectableViewDirection(self)
    }

    override func updateTheme(isDark: Bool) {
        mainWrapperView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark).cgColor
    }

    func updateStringData(title: String, optionTitle: String, listOption: [String], subTitle: String? = nil) {
        headerView.updateStringData(title: title, optionTitle: optionTitle, listOption: listOption)
        self.subTitle = subTitle
        footer.content = subTitle ?? "Explain me!".localize()
        update()
    }
}

extension SelectableView: SelectableHeaderViewDelegate {
    func selectableHeaderViewDidSelect(_ option: String) {
        delegate?.selectableViewSelect(self, option: option)
    }
}

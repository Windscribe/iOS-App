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
    private(set) var type: SelectionViewType
    private(set) var currentOption: String
    private let isDarkMode: BehaviorSubject<Bool>
    private let disposeBag = DisposeBag()

    weak var delegate: SelectableViewDelegate?


    private lazy var mainWrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        return view
    }()

    private lazy var headerView: SelectableHeaderView = {
        let header = SelectableHeaderView(type: type,
                                          optionTitle: currentOption,
                                          isDarkMode: isDarkMode)
        switch type.type {
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

    init(type: SelectionViewType,
         currentOption: String,
         isDarkMode: BehaviorSubject<Bool>,
         delegate: SelectableViewDelegate? = nil) {
        self.type = type
        self.currentOption = currentOption
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
        footer.content = type.description
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

    func refreshLocalization(optionTitle: String) {
        headerView.refreshLocalization(optionTitle: optionTitle)
        footer.content = type.description
        update()
    }
}

extension SelectableView: SelectableHeaderViewDelegate {
    func selectableHeaderViewDidSelect(_ option: String) {
        delegate?.selectableViewSelect(self, option: option)
    }
}

//
//	ConnectionModeItemView.swift
//	Windscribe
//
//	Created by Thomas on 25/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Combine
import Foundation
import RxSwift
import UIKit

protocol ConnectionModeItemViewDelegate: AnyObject {
    func connectionModeItemViewDidSelectDropdownButton(_ sender: DropdownButton, _ view: ConnectionModeItemView)
}

class ConnectionModeItemView: UIView {
    lazy var titleLabel = UILabel()
    lazy var dropdownView = DropdownButton(isDarkMode: isDarkMode)

    weak var delegate: ConnectionModeItemViewDelegate?

    var isDarkMode: CurrentValueSubject<Bool, Never>
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    init(isDarkMode: CurrentValueSubject<Bool, Never>) {
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        initViews()
        addConstraints()
        bindViews(isDarkMode: isDarkMode)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindViews(isDarkMode: CurrentValueSubject<Bool, Never>) {
        isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                guard let self = self else { return }
                self.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark)
                self.titleLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            }
            .store(in: &cancellables)
    }

    private func addConstraints() {
        addSubview(titleLabel)
        titleLabel.makeTopAnchor(constant: 16)
        titleLabel.makeLeadingAnchor(constant: 16)
        titleLabel.makeBottomAnchor(constant: 16)

        addSubview(dropdownView)
        dropdownView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16).isActive = true
        dropdownView.makeHeightAnchor(equalTo: 20)
        dropdownView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        dropdownView.makeTrailingAnchor(constant: 16)
    }

    private func initViews() {
        titleLabel.font = UIFont.text(size: 14)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        dropdownView.translatesAutoresizingMaskIntoConstraints = false
        dropdownView.delegate = self
    }
}

extension ConnectionModeItemView: DropdownButtonDelegate {
    func dropdownButtonTapped(_ sender: DropdownButton) {
        delegate?.connectionModeItemViewDidSelectDropdownButton(sender, self)
    }
}

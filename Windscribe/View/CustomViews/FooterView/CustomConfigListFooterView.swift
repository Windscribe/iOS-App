//
//  CustomConfigListFooterView.swift
//  Windscribe
//
//  Created by Yalcin on 2020-06-30.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import Combine
import RealmSwift
import RxSwift
import SafariServices
import UIKit

class CustomConfigListFooterView: WSView {
    weak var delegate: AddCustomConfigDelegate?
    lazy var actionButton = UIButton(type: .system)
    lazy var label = UILabel()
    lazy var backgroundView = UIView()
    let activeLanguage: CurrentValueSubject<Languages, Never>
    let isDarkMode: CurrentValueSubject<Bool, Never>
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    init(activeLanguage: CurrentValueSubject<Languages, Never>, isDarkMode: CurrentValueSubject<Bool, Never>) {
        self.activeLanguage = activeLanguage
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)

        addSubview(backgroundView)

        actionButton.backgroundColor = UIColor.clear
        addSubview(actionButton)

        label.font = UIFont.text(size: 16)
        label.textColor = UIColor.cyberBlue
        label.layer.opacity = 0.7
        addSubview(label)

        bindViews()
    }

    private func bindViews() {
        actionButton.rx.tap.bind { [weak self] _ in
            self?.delegate?.addCustomConfig()
        }.disposed(by: disposeBag)

        activeLanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.label.text = TextsAsset.addCustomConfig
            }
            .store(in: &cancellables)

        isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.backgroundView.backgroundColor = .from(.pressStateColor, isDark)
                self?.backgroundColor = .from(.backgroundColor, isDark)
            }
            .store(in: &cancellables)
    }

    override func setupLocalized() {
        label.text = TextsAsset.addCustomConfig
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func actionButtonTapped() {
        delegate?.addCustomConfig()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        layoutViews()
    }

    private func layoutViews() {
        let centerYConstant = UIScreen.hasTopNotch ? -10.0 : 0.0
        NSLayoutConstraint.activate([
            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.rightAnchor.constraint(equalTo: rightAnchor),
            backgroundView.leftAnchor.constraint(equalTo: leftAnchor),

            // label
            label.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor, constant: centerYConstant),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.heightAnchor.constraint(equalToConstant: 21),

            // actionButton
            actionButton.topAnchor.constraint(equalTo: topAnchor),
            actionButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            actionButton.leftAnchor.constraint(equalTo: leftAnchor),
            actionButton.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }
}

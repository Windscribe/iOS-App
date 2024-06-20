//
//  CardHeaderContainerView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 01/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class CardHeaderContainerView: UIView {
    var stackContainerView = UIStackView()
    var allButton = LargeTapAreaImageButton()
    var favButton = LargeTapAreaImageButton()
    var flixButton = LargeTapAreaImageButton()
    var staticIpButton = LargeTapAreaImageButton()
    var configButton = LargeTapAreaImageButton()
    var spacerView = UIView()
    var startSearchButton = LargeTapAreaImageButton()
    var headerSelectorView = UIView()

    var viewModel: CardTopViewModelType!

    var disposeBag = DisposeBag()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
    }

    func loadView() {
        addViews()
        addViewConstraints()
        bindView()
    }

    private func updateLayourForTheme(isDarkMode: Bool) {
        if isDarkMode {
            allButton.setImage(UIImage(named: ImagesAsset.DarkMode.serversAll), for: .normal)
            favButton.setImage(UIImage(named: ImagesAsset.DarkMode.serversFav), for: .normal)
            flixButton.setImage(UIImage(named: ImagesAsset.DarkMode.serversFlix), for: .normal)
            staticIpButton.setImage(UIImage(named: ImagesAsset.DarkMode.serversStaticIP), for: .normal)
            configButton.setImage(UIImage(named: ImagesAsset.DarkMode.serversConfig), for: .normal)
            startSearchButton.setImage(UIImage(named: ImagesAsset.DarkMode.search), for: .normal)
            headerSelectorView.backgroundColor = UIColor.white
        } else {
            allButton.setImage(UIImage(named: ImagesAsset.Servers.all), for: .normal)
            favButton.setImage(UIImage(named: ImagesAsset.Servers.fav), for: .normal)
            flixButton.setImage(UIImage(named: ImagesAsset.Servers.flix), for: .normal)
            staticIpButton.setImage(UIImage(named: ImagesAsset.Servers.staticIP), for: .normal)
            configButton.setImage(UIImage(named: ImagesAsset.Servers.config), for: .normal)
            startSearchButton.setImage(UIImage(named: ImagesAsset.search), for: .normal)
            headerSelectorView.backgroundColor = UIColor.black
        }
    }

    private func addViews() {
        stackContainerView.axis = .horizontal
        stackContainerView.spacing = 34

        addSubview(headerSelectorView)
        addSubview(stackContainerView)

        stackContainerView.addArrangedSubviews([allButton, favButton, flixButton, staticIpButton, configButton, spacerView, startSearchButton])
    }

    private func addViewConstraints() {
        stackContainerView.translatesAutoresizingMaskIntoConstraints = false
        allButton.translatesAutoresizingMaskIntoConstraints = false
        favButton.translatesAutoresizingMaskIntoConstraints = false
        flixButton.translatesAutoresizingMaskIntoConstraints = false
        staticIpButton.translatesAutoresizingMaskIntoConstraints = false
        configButton.translatesAutoresizingMaskIntoConstraints = false
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        startSearchButton.translatesAutoresizingMaskIntoConstraints = false
        headerSelectorView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // stackContainerView
            stackContainerView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            stackContainerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            stackContainerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24),
            stackContainerView.heightAnchor.constraint(equalToConstant: 16),

            // headerSelectorView
            headerSelectorView.bottomAnchor.constraint(equalTo: stackContainerView.bottomAnchor, constant: 4),
            headerSelectorView.centerXAnchor.constraint(equalTo: allButton.centerXAnchor),
            headerSelectorView.widthAnchor.constraint(equalToConstant: 16),
            headerSelectorView.heightAnchor.constraint(equalToConstant: 2),

            // allButton
            allButton.widthAnchor.constraint(equalToConstant: 16),

            // favButton
            favButton.widthAnchor.constraint(equalToConstant: 16),

            // flixButton
            flixButton.widthAnchor.constraint(equalToConstant: 16),

            // staticIpButton
            staticIpButton.widthAnchor.constraint(equalToConstant: 24),

            // configButton
            configButton.widthAnchor.constraint(equalToConstant: 24),

            // startSearchButton
            startSearchButton.widthAnchor.constraint(equalToConstant: 16)
        ])
    }

    private func showPresentingListIcon(cardButtonType: CardHeaderButtonType) {
        UIView.animate(withDuration: 0.2) {
            switch cardButtonType {
            case .all:
                self.headerSelectorView.center.x = self.allButton.center.x + 24
            case .fav:
                self.headerSelectorView.center.x = self.favButton.center.x + 24
            case .flix:
                self.headerSelectorView.center.x = self.flixButton.center.x + 24
            case .staticIP:
                self.headerSelectorView.center.x = self.staticIpButton.center.x + 24
            case .config:
                self.headerSelectorView.center.x = self.configButton.center.x + 24
            case .startSearch:
                self.headerSelectorView.center.x = self.startSearchButton.center.x + 24
            }
        }
    }

    private func bindView() {
        allButton.rx.tap.bind {
            self.viewModel.allSelected()
        }.disposed(by: disposeBag)
        favButton.rx.tap.bind {
            self.viewModel.favSelected()
        }.disposed(by: disposeBag)
        flixButton.rx.tap.bind {
            self.viewModel.flixSelected()
        }.disposed(by: disposeBag)
        staticIpButton.rx.tap.bind {
            self.viewModel.staticSelected()
        }.disposed(by: disposeBag)
        configButton.rx.tap.bind {
            self.viewModel.configSelected()
        }.disposed(by: disposeBag)
        startSearchButton.rx.tap.bind {
            self.viewModel.startSearchSelected()
        }.disposed(by: disposeBag)

        viewModel.isDarkMode.subscribe { isDarkMode in
            self.updateLayourForTheme(isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)

        viewModel.isActive.subscribe { isActive in
            self.stackContainerView.isHidden = !isActive
            self.isUserInteractionEnabled = isActive
        }.disposed(by: disposeBag)

        viewModel.selectedAction.subscribe {
            self.showPresentingListIcon(cardButtonType: $0)
        }.disposed(by: disposeBag)
    }
}

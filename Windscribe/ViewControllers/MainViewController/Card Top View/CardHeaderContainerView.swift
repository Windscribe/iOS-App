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

fileprivate class ButtonImageView: UIView {
    let button = UIButton()
    let imageView = UIImageView()
    var disposeBag = DisposeBag()

    init(imageName: String, imageSize: CGFloat, tapAction: @escaping () -> Void) {
        super.init(frame: .zero)
        self.addSubview(imageView)
        self.addSubview(button)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalTo: self.widthAnchor),
            button.heightAnchor.constraint(equalTo: self.heightAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: imageSize),
            imageView.heightAnchor.constraint(equalToConstant: 16)
        ])

        button.rx.tap.bind {
            tapAction()
        }.disposed(by: disposeBag)
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CardHeaderContainerView: UIView {
    var stackContainerView = UIStackView()
    fileprivate lazy var allButton = ButtonImageView(imageName: ImagesAsset.DarkMode.serversAll, imageSize: 16, tapAction: viewModel.allSelected)
    fileprivate lazy var favButton = ButtonImageView(imageName: ImagesAsset.DarkMode.serversFav, imageSize: 16, tapAction: viewModel.favSelected)
    fileprivate lazy var flixButton = ButtonImageView(imageName: ImagesAsset.DarkMode.serversFlix, imageSize: 16, tapAction: viewModel.flixSelected)
    fileprivate lazy var staticIpButton = ButtonImageView(imageName: ImagesAsset.DarkMode.serversStaticIP, imageSize: 24, tapAction: viewModel.staticSelected)
    fileprivate lazy var configButton = ButtonImageView(imageName: ImagesAsset.DarkMode.serversConfig, imageSize: 24, tapAction: viewModel.configSelected)
    fileprivate lazy var startSearchButton = ButtonImageView(imageName: ImagesAsset.DarkMode.search, imageSize: 16, tapAction: viewModel.startSearchSelected)
    var spacerView = UIView()
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
            allButton.setImage(UIImage(named: ImagesAsset.DarkMode.serversAll))
            favButton.setImage(UIImage(named: ImagesAsset.DarkMode.serversFav))
            flixButton.setImage(UIImage(named: ImagesAsset.DarkMode.serversFlix))
            staticIpButton.setImage(UIImage(named: ImagesAsset.DarkMode.serversStaticIP))
            configButton.setImage(UIImage(named: ImagesAsset.DarkMode.serversConfig))
            startSearchButton.setImage(UIImage(named: ImagesAsset.DarkMode.search))
            headerSelectorView.backgroundColor = UIColor.white
        } else {
            allButton.setImage(UIImage(named: ImagesAsset.Servers.all))
            favButton.setImage(UIImage(named: ImagesAsset.Servers.fav))
            flixButton.setImage(UIImage(named: ImagesAsset.Servers.flix))
            staticIpButton.setImage(UIImage(named: ImagesAsset.Servers.staticIP))
            configButton.setImage(UIImage(named: ImagesAsset.Servers.config))
            startSearchButton.setImage(UIImage(named: ImagesAsset.search))
            headerSelectorView.backgroundColor = UIColor.black
        }
    }

    private func addViews() {
        stackContainerView.axis = .horizontal
        stackContainerView.spacing = 10

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
            stackContainerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            stackContainerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            stackContainerView.heightAnchor.constraint(equalTo: self.heightAnchor),

            // headerSelectorView
            headerSelectorView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -2),
            headerSelectorView.centerXAnchor.constraint(equalTo: allButton.centerXAnchor),
            headerSelectorView.widthAnchor.constraint(equalToConstant: 16),
            headerSelectorView.heightAnchor.constraint(equalToConstant: 2),

            // allButton
            allButton.widthAnchor.constraint(equalToConstant: 36),

            // favButton
            favButton.widthAnchor.constraint(equalToConstant: 36),

            // flixButton
            flixButton.widthAnchor.constraint(equalToConstant: 36),

            // staticIpButton
            staticIpButton.widthAnchor.constraint(equalToConstant: 36),

            // configButton
            configButton.widthAnchor.constraint(equalToConstant: 36),

            // startSearchButton
            startSearchButton.widthAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func showPresentingListIcon(cardButtonType: CardHeaderButtonType) {
        UIView.animate(withDuration: 0.2) {
            switch cardButtonType {
            case .all:
                self.headerSelectorView.center.x = self.allButton.center.x + 12
            case .fav:
                self.headerSelectorView.center.x = self.favButton.center.x + 12
            case .flix:
                self.headerSelectorView.center.x = self.flixButton.center.x + 12
            case .staticIP:
                self.headerSelectorView.center.x = self.staticIpButton.center.x + 12
            case .config:
                self.headerSelectorView.center.x = self.configButton.center.x + 12
            case .startSearch:
                self.headerSelectorView.center.x = self.startSearchButton.center.x + 12
            }
        }
    }

    private func bindView() {
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

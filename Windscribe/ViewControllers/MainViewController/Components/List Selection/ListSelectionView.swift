//
//  ListSelectionView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 01/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

private class ButtonImageView: UIView {
    let button = UIButton()
    let imageView = UIImageView()
    var disposeBag = DisposeBag()

    convenience init(imageName: String, imageSize: CGFloat, tapAction: @escaping () -> Void) {
        self.init(imageName: imageName, imageWidth: imageSize, imageHeight: imageSize, tapAction: tapAction)
    }

    init(imageName: String, imageWidth: CGFloat, imageHeight: CGFloat, tapAction: @escaping () -> Void) {
        super.init(frame: .zero)
        self.addSubview(imageView)
        self.addSubview(button)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: imageName)
        imageView.contentMode = .scaleAspectFill

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalTo: self.widthAnchor),
            button.heightAnchor.constraint(equalTo: self.heightAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: imageWidth),
            imageView.heightAnchor.constraint(equalToConstant: imageHeight)
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

class ListSelectionView: UIView {
    var stackContainerView = UIStackView()
    fileprivate lazy var allButton = ButtonImageView(imageName: ImagesAsset.Servers.serversAll, imageSize: 24, tapAction: viewModel.allSelected)
    fileprivate lazy var favButton = ButtonImageView(imageName: ImagesAsset.favEmpty, imageSize: 24, tapAction: viewModel.favSelected)
    fileprivate lazy var staticIpButton = ButtonImageView(imageName: ImagesAsset.Servers.staticIP, imageWidth: 18, imageHeight: 22, tapAction: viewModel.staticSelected)
    fileprivate lazy var configButton = ButtonImageView(imageName: ImagesAsset.Servers.config, imageSize: 24, tapAction: viewModel.configSelected)
    fileprivate lazy var startSearchButton = ButtonImageView(imageName: ImagesAsset.search, imageSize: 20, tapAction: viewModel.startSearchSelected)
    var spacerView = UIView()
    var gradientView = UIView()

    var viewModel: ListSelectionViewModelType!

    var disposeBag = DisposeBag()

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
    }

    func setSearchHidden(_ isHidden: Bool) {
        gradientView.backgroundColor = isHidden ? .clear : .nightBlue
    }

    func loadView() {
        addViews()
        addViewConstraints()
        bindView()
        drawGradientView()
    }

    func redrawGradientView() {
        gradientView.layer.sublayers = []
        drawGradientView()
    }

    private func drawGradientView() {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.nightBlueOpacity(opacity: 0.3).cgColor, UIColor.nightBlue.cgColor]
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width + 2, height: 54)
        gradientView.layer.addSublayer(gradient)
        gradientView.layer.cornerRadius = 24
        gradientView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        gradientView.layer.masksToBounds = true
        gradientView.layer.borderWidth = 1
        gradientView.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.1).cgColor
    }

    private func addViews() {
        stackContainerView.axis = .horizontal
        stackContainerView.spacing = 16

        gradientView.backgroundColor = .clear

        addSubview(gradientView)
        addSubview(stackContainerView)

        stackContainerView.addArrangedSubviews([allButton, favButton, staticIpButton, configButton, spacerView, startSearchButton])

        allButton.imageView.setImageColor(color: .white)
        favButton.imageView.setImageColor(color: .white)
        staticIpButton.imageView.setImageColor(color: .white)
        configButton.imageView.setImageColor(color: .white)
        startSearchButton.imageView.setImageColor(color: .white)

    }

    private func addViewConstraints() {
        stackContainerView.translatesAutoresizingMaskIntoConstraints = false
        allButton.translatesAutoresizingMaskIntoConstraints = false
        favButton.translatesAutoresizingMaskIntoConstraints = false
        staticIpButton.translatesAutoresizingMaskIntoConstraints = false
        configButton.translatesAutoresizingMaskIntoConstraints = false
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        startSearchButton.translatesAutoresizingMaskIntoConstraints = false
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // gradientView
            gradientView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: -1),
            gradientView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 1),
            gradientView.topAnchor.constraint(equalTo: self.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            // stackContainerView
            stackContainerView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            stackContainerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            stackContainerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            stackContainerView.heightAnchor.constraint(equalTo: self.heightAnchor),

            // allButton
            allButton.widthAnchor.constraint(equalToConstant: 32),

            // favButton
            favButton.widthAnchor.constraint(equalToConstant: 32),

            // staticIpButton
            staticIpButton.widthAnchor.constraint(equalToConstant: 32),

            // configButton
            configButton.widthAnchor.constraint(equalToConstant: 32),

            // startSearchButton
            startSearchButton.widthAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func showPresentingListIcon(cardButtonType: CardHeaderButtonType) {
        UIView.animate(withDuration: 0.2) {
            self.allButton.imageView.image = UIImage(named: cardButtonType == .all ?
                                                     ImagesAsset.Servers.allSelected : ImagesAsset.Servers.serversAll)
            self.favButton.imageView.image = UIImage(named: cardButtonType == .fav ?
                                                     ImagesAsset.favFull : ImagesAsset.favEmpty)
            self.staticIpButton.imageView.image = UIImage(named: cardButtonType == .staticIP ?
                                                          ImagesAsset.Servers.staticIPSelected : ImagesAsset.Servers.staticIP)
            self.configButton.imageView.image = UIImage(named: cardButtonType == .config ?
                                                        ImagesAsset.Servers.configSelected : ImagesAsset.Servers.config)

            self.allButton.imageView.layer.opacity = cardButtonType == .all ? 1.0 : 0.7
            self.favButton.imageView.layer.opacity = cardButtonType == .fav ? 1.0 : 0.7
            self.staticIpButton.imageView.layer.opacity = cardButtonType == .staticIP ? 1.0 : 0.7
            self.configButton.imageView.layer.opacity = cardButtonType == .config ? 1.0 : 0.7
        }
    }

    private func bindView() {
        viewModel.isActive.subscribe { isActive in
            self.stackContainerView.isHidden = !isActive
            self.isUserInteractionEnabled = isActive
        }.disposed(by: disposeBag)

        viewModel.selectedAction.subscribe {
            self.showPresentingListIcon(cardButtonType: $0)
        }.disposed(by: disposeBag)
    }
}

//
//  StaticIpEmptyView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject
import UIKit

enum ListEmptyViewType {
    case staticIP, customConfig, favNodes

    var description: String {
        switch self {
        case .staticIP:
            return TextsAsset.noStaticIPs
        case .customConfig:
            return TextsAsset.addCustomConfigDescription
        case .favNodes:
            return TextsAsset.Favorites.noFavorites
        }
    }

    var buttonTitle: String {
        switch self {
        case .staticIP:
            return TextsAsset.addStaticIP
        case .customConfig:
            return TextsAsset.addCustomConfig
        case .favNodes:
            return ""
        }
    }

    var imageName: String {
        switch self {
        case .staticIP:
            return ImagesAsset.Servers.staticIP
        case .customConfig:
            return ImagesAsset.customConfigIcon
        case .favNodes:
            return ImagesAsset.favEmpty
        }
    }

    var showButton: Bool {
        switch self {
        case .staticIP, .customConfig:
            return true
        case .favNodes:
            return false
        }
    }
}

class ListEmptyView: UIView {
    var isDarkMode: BehaviorSubject<Bool>
    let disposeBag = DisposeBag()
    lazy var languageManager = Assembler.resolve(LanguageManager.self)

    let label = UILabel()
    let button = UIButton()
    let imageView = UIImageView()
    var config = UIButton.Configuration.filled()

    var addAction: (() -> Void)?
    private var type: ListEmptyViewType

    init(type: ListEmptyViewType, isDarkMode: BehaviorSubject<Bool>) {
        self.isDarkMode = isDarkMode
        self.type = type
        super.init(frame: .zero)
        bindViews()
        updateUI()
    }

    private func updateUI() {
        backgroundColor = UIColor.clear
        imageView.image = UIImage(named: type.imageName)?
            .withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.opacity = 0.7
        addSubview(imageView)

        label.textAlignment = .center
        label.font = UIFont.text(size: 16)
        label.text = type.description
        label.numberOfLines = 0
        label.layer.opacity = 0.7
        addSubview(label)

        if !type.showButton {
            button.isHidden = true
            config.baseBackgroundColor = .clear
        } else {
            config.title = type.buttonTitle
            config.titleAlignment = .center
            config.titleTextAttributesTransformer =
              UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.text(size: 16)
                return outgoing
              }
            config.baseBackgroundColor = .whiteWithOpacity(opacity: 0.1)
            config.baseForegroundColor = .white
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24)

            button.addAction(UIAction { _ in
                self.addAction?()
            }, for: .touchUpInside)
        }
        button.configuration = config
        addSubview(button)
    }

    func updateLayout() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // imageView
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalToConstant: 32),
            imageView.widthAnchor.constraint(equalToConstant: 32),

            // label
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 80),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -80),

            // button
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16)
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindViews() {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: {
            self.label.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.imageView.tintColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
        }).disposed(by: disposeBag)
        languageManager.activelanguage.subscribe(onNext: { [weak self] _ in
            self?.label.text = self?.type.description
            self?.config.title = self?.type.buttonTitle
        }, onError: { _ in }).disposed(by: disposeBag)
    }
}

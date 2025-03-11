//
//  CustomConfigEmptyView.swift
//  Windscribe
//
//  Created by Thomas on 16/02/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject
import UIKit

class CustomConfigEmptyView: UIView {
    var isDarkMode: BehaviorSubject<Bool>
    let disposeBag = DisposeBag()
    lazy var languageManager = Assembler.resolve(LanguageManagerV2.self)

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: ImagesAsset.customConfigIcon)?.withRenderingMode(.alwaysTemplate)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.makeWidthAnchor(equalTo: 34)
        imageView.makeHeightAnchor(equalTo: 34)
        return imageView
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.text(size: 16)
        label.numberOfLines = 0
        label.text = TextsAsset.addCustomConfigDescription
        return label
    }()

    lazy var addCustomButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        button.setTitle(TextsAsset.addCustomConfig, for: .normal)
        button.setTitleColor(UIColor.blackWithOpacity(opacity: 1), for: .normal)
        button.titleLabel?.font = UIFont.text(size: 16)
        button.backgroundColor = UIColor.seaGreen
        button.addTarget(self, action: #selector(addCustomConfigTouchUpInside(_:)), for: .touchUpInside)
        return button
    }()

    var addCustomConfigAction: (() -> Void)?

    @objc private func addCustomConfigTouchUpInside(_: UIButton) {
        addCustomConfigAction?()
    }

    init(frame: CGRect, isDarkMode: BehaviorSubject<Bool>) {
        self.isDarkMode = isDarkMode
        super.init(frame: frame)
        backgroundColor = UIColor.clear

        addSubview(containerView)
        for item in [imageView, label, addCustomButton] {
            containerView.addSubview(item)
        }

        containerView.makeCenter(xConstant: 20)
        containerView.makeLeadingAnchor(constant: 50)
        containerView.makeTrailingAnchor(constant: 50)

        imageView.makeTopAnchor()
        imageView.makeCenterXAnchor()

        label.makeTopAnchor(with: imageView, constant: 20)
        label.makeLeadingAnchor()
        label.makeTrailingAnchor()

        addCustomButton.makeTopAnchor(with: label, constant: 25)
        addCustomButton.makeCenterXAnchor()
        addCustomButton.makeBottomAnchor()
        bindViews()
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
        languageManager.activelanguage.subscribe(onNext: { [self] _ in
            self.label.text = TextsAsset.addCustomConfigDescription
            addCustomButton.setTitle(TextsAsset.addCustomConfig, for: .normal)
        }, onError: { _ in }).disposed(by: disposeBag)
    }
}

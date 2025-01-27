//
//  SwitchHeaderView.swift
//  Windscribe
//
//  Created by Thomas on 12/08/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class SwitchHeaderView: UIStackView {
    private(set) var title: String
    private(set) var imageAsset: String?
    var connectionSecureViewSwitchAction: (() -> Void)?
    var isDarkMode: BehaviorSubject<Bool>

    let disposeBag = DisposeBag()

    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.bold(size: 16)
        lbl.text = title
        return lbl
    }()

    private lazy var iconImage: UIImageView = {
        let imageView = UIImageView()
        if let imageAsset = imageAsset {
            imageView.image = UIImage(named: imageAsset)
        } else {
            imageView.layer.cornerRadius = 4
            imageView.layer.borderWidth = 2
        }
        imageView.contentMode = .scaleAspectFit
        imageView.anchor(width: 18, height: 18)
        return imageView
    }()

    lazy var switchButton: SwitchButton = {
        let switchButton = SwitchButton(isDarkMode: isDarkMode)
        switchButton.layer.cornerRadius = 12
        switchButton.clipsToBounds = true
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.addTarget(self, action: #selector(switchButtonTapped), for: .touchUpInside)
        return switchButton
    }()

    private lazy var wrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()

    init(title: String, icon: String?, isDarkMode: BehaviorSubject<Bool>) {
        self.title = title
        imageAsset = icon
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
            self.titleLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            if self.iconImage.image != nil {
                self.iconImage.updateTheme(isDark: $0)
            } else {
                self.iconImage.layer.borderColor = (ThemeUtils.primaryTextColor(isDarkMode: $0)).cgColor
            }
            self.wrapperView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
        }.disposed(by: disposeBag)
    }

    private func setup() {
        addArrangedSubviews([
            iconImage,
            titleLabel,
            UIView(),
        ])
        spacing = 16
        axis = .horizontal
        setPadding(UIEdgeInsets(inset: 16))
        addSubview(wrapperView)
        wrapperView.fillSuperview()
        wrapperView.sendToBack()
        clipsToBounds = true
        addSubview(switchButton)
        switchButton.makeHeightAnchor(equalTo: 25)
        switchButton.makeWidthAnchor(equalTo: 45)
        switchButton.makeCenterYAnchor()
        switchButton.makeTrailingAnchor(constant: 16)
//        cornerBottomEdge(true)
    }

    @objc private func switchButtonTapped() {
        switchButton.toggle()
        connectionSecureViewSwitchAction?()
    }

    func cornerBottomEdge(_ haveCorner: Bool) {
        wrapperView.layer.mask = nil
        if !haveCorner {
            wrapperView.makeRoundCorners(corners: [.topLeft, .topRight], radius: 6)
        } else {
            wrapperView.makeRoundCorners(corners: [.topLeft, .topRight, .bottomRight, .bottomLeft], radius: 6)
        }
    }
}

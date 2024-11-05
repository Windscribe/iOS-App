//
//  InfoFooterView.swift
//  Windscribe
//
//  Created by Thomas on 22/07/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class FooterView: UIStackView {
    var explainTapped: (() -> Void)?
    var content: String = "" {
        didSet {
            update()
        }
    }

    private lazy var contentLabel: UILabel = {
        let lbl = UILabel()
        lbl.layer.opacity = 0.5
        lbl.font = UIFont.text(size: 14)
        lbl.numberOfLines = 0
        return lbl
    }()

    private lazy var iconImage: UIImageView = {
        let image = UIImageView(image: UIImage(named: "learn-more-ic")?.withRenderingMode(.alwaysTemplate))
        image.anchor(width: 16, height: 16)
        image.layer.opacity = 0.5
        return image
    }()

    private lazy var iconTapView: UIView = {
        let vw = UIView()
        vw.isUserInteractionEnabled = true
        vw.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iconTapped)))
        return vw
    }()

    private let disposeBag = DisposeBag()

    init(isDarkMode: BehaviorSubject<Bool>) {
        super.init(frame: .zero)
        setup()
        bindViews(isDarkMode: isDarkMode)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        axis = .vertical
        setPadding(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 36))
        addArrangedSubviews([
            contentLabel,
        ])
        addSubview(iconImage)
        iconImage.anchor(top: topAnchor, right: rightAnchor, paddingTop: 16, paddingRight: 16)
        addSubview(iconTapView)
        iconTapView.anchor(top: iconImage.topAnchor, right: iconImage.rightAnchor, paddingTop: -4, paddingRight: -4, width: 24, height: 24)
    }

    private func update() {
        contentLabel.text = content
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.contentLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.iconImage.tintColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.iconImage.updateTheme(isDark: $0)
        }).disposed(by: disposeBag)
    }

    func hideShowExplainIcon(_ ishidden: Bool = true) {
        iconImage.isHidden = ishidden
    }

    @objc private func iconTapped() {
        explainTapped?()
    }
}

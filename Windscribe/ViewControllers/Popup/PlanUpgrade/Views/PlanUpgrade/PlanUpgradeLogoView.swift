//
//  PlanUpgradeLogoView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-03.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit

class PlanUpgradeLogoView: UIView {

    // MARK: UI Components

    private let container = UIView()
//    private let containerBackground = PlanUpgradeStarsBackgroundView()
    private let logoStackView = UIStackView()
    private let logoImageView = UIImageView()
    private let graphicLogoImageView: AsyncImageView?
    private let graphicLogoGridImageView = UIImageView()

    // MARK: Initializer

    init(urlString: String? = nil, placeHolder: UIImage) {
        self.graphicLogoImageView = AsyncImageView(
            urlString: urlString,
            placeholder: UIImage(named: "hero-graphic")
        )

        super.init(frame: .zero)

        setTheme()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup UI

    private func setTheme() {
        container.do {
            $0.isUserInteractionEnabled = false
            $0.clipsToBounds = false
            $0.layer.masksToBounds = false
        }

//        containerBackground.do {
//            $0.clipsToBounds = isRegularSizeClass ? false : true
//            $0.isHidden = isRegularSizeClass
//        }

        logoStackView.do {
            $0.axis = .vertical
            $0.spacing = isRegularSizeClass ? (isPortrait ? 40 : 30) : 20
            $0.alignment = .center
            $0.distribution = .fill
        }

        logoImageView.do {
            $0.contentMode = .scaleAspectFit
            $0.image = UIImage(named: "pro-logo")
        }

        graphicLogoImageView?.do {
            $0.contentMode = .scaleAspectFit
        }

        graphicLogoGridImageView.do {
            $0.contentMode = isRegularSizeClass ? .scaleToFill : .scaleAspectFit
            $0.image = UIImage(named: "hero-grid")
        }
    }

    // MARK: Layout UI

    private func setupLayout() {
        addSubview(container)

        container.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

//        container.addSubview(containerBackground)
//
//        containerBackground.snp.makeConstraints {
//            $0.edges.equalToSuperview()
//        }

        container.addSubview(logoStackView)

        logoStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        guard let graphicLogoImageView else { return }

        let graphiclogoContentView = UIView()
        graphiclogoContentView.addSubview(graphicLogoGridImageView)
        graphiclogoContentView.addSubview(graphicLogoImageView)

        graphicLogoImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        graphicLogoGridImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(graphicLogoImageView.snp.bottom).multipliedBy(0.5)
            $0.width.equalTo(graphicLogoImageView).multipliedBy(isRegularSizeClass ? 2 : 1)
            $0.bottom.equalToSuperview()
        }

        graphiclogoContentView.bringSubviewToFront(graphicLogoImageView)
        logoStackView.addArrangedSubviews([logoImageView, graphiclogoContentView])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let newSpacing: CGFloat = isRegularSizeClass ? (isPortrait ? 40 : 30) : 20
        logoStackView.spacing = newSpacing
    }
}

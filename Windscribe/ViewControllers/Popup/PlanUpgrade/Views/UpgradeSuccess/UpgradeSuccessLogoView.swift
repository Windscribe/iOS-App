//
//  UpgradeSuccessLogoView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit

class UpgradeSuccessLogoView: UIView {

    // UI Components

    private let container = UIView()
    private let logoStackView = UIStackView()
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setTheme()
        doLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setTheme() {
        container.do {
            $0.isUserInteractionEnabled = false
        }

        logoStackView.do {
            $0.axis = .vertical
            $0.spacing = isRegularSizeClass ? (isPortrait ? 32 : 20) : 18
            $0.alignment = .center
            $0.distribution = .fill
        }

        logoImageView.do {
            $0.image = UIImage(named: ImagesAsset.Subscriptions.successLogo)
            $0.contentMode = .scaleAspectFit
        }

        titleLabel.do {
            $0.text = TextsAsset.UpgradeView.planBenefitSuccessScreenTitle
            $0.font = UIFont.bold(textStyle: .title2)
            $0.textColor = .white
            $0.textAlignment = .center
            $0.numberOfLines = 0
        }

        subtitleLabel.do {
            $0.text = TextsAsset.UpgradeView.planBenefitSuccessScreenDescription
            $0.font = UIFont.regular(textStyle: .subheadline)
            $0.textColor = .whiteWithOpacity(opacity: 0.8)
            $0.textAlignment = .center
            $0.numberOfLines = 0
        }

    }

    private func doLayout() {
        addSubview(container)

        container.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        container.addSubview(logoStackView)

        logoStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        logoStackView.addArrangedSubviews([logoImageView, titleLabel, subtitleLabel])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let newSpacing: CGFloat = isRegularSizeClass ? (isPortrait ? 32 : 20) : 18
        logoStackView.spacing = newSpacing
    }
}

//
//  PlanUpgradeBenefitView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-03.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit

class PlanUpgradeBenefitView: UIView {

    // MARK: UI Components

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconImageView = UIImageView()
    private let textStackView = UIStackView()
    private let rowStackView = UIStackView()

    // MARK: Initializer

    init(title: String, subtitle: String, imageName: String) {
        super.init(frame: .zero)

        setTheme(title: title, subtitle: subtitle, imageName: imageName)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup UI

    private func setTheme(title: String, subtitle: String, imageName: String) {
        titleLabel.do {
            $0.text = title
            $0.font = UIFont.medium(textStyle: .subheadline)
            $0.adjustsFontForContentSizeCategory = true
            $0.textColor = .white
        }

        subtitleLabel.do {
            $0.text = subtitle
            $0.font = UIFont.text(textStyle: .footnote)
            $0.adjustsFontForContentSizeCategory = true
            $0.textColor = .whiteWithOpacity(opacity: 0.5)
            $0.numberOfLines = 0
        }

        iconImageView.do {
            $0.image = UIImage(named: imageName)
            $0.contentMode = .scaleAspectFit
        }

        textStackView.do {
            $0.axis = .vertical
            $0.spacing = isRegularSizeClass ? (isPortrait ? 6 : 4) : 4
        }

        rowStackView.do {
            $0.axis = .horizontal
            $0.spacing = isRegularSizeClass ? (isPortrait ? 25 : 10) : 10
            $0.alignment = .center
            $0.distribution = .fill
        }
    }

    // MARK: Layout UI

    private func setupLayout() {
        textStackView.addArrangedSubviews([titleLabel, subtitleLabel])
        rowStackView.addArrangedSubviews([textStackView, iconImageView])

        addSubview(rowStackView)

        iconImageView.snp.makeConstraints {
            $0.width.height.equalTo(25)
        }

        rowStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        iconImageView.do {
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let newRowSpacing: CGFloat = isRegularSizeClass ? (isPortrait ? 25 : 10) : 10
        rowStackView.spacing = newRowSpacing

        let newTextSpacing: CGFloat = isRegularSizeClass ? (isPortrait ? 6 : 4) : 4
        textStackView.spacing = newTextSpacing
    }
}

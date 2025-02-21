//
//  PlanUpgradePromoView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit

class PlanUpgradePromoView: UIView {

    // MARK: UI Components

    private let promoContainer = UIView()
    private let promoContainerBackgroundView = PlanUpgradeStarsBackgroundView()
    private let promoContainerOverlay = UIView()
    private let promoTitleLabel = UILabel()
    private let promoPriceLabel = UILabel()
    private let promoSubtitleLabel = UILabel()
    private let promoDiscountLabel = UILabel()
    private let promoDiscountLabelContainer = UIView()

    // Border Layer
    private let borderLayer = CAShapeLayer()

    // MARK: Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)

        setTheme()
        doLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Layout Updates

    override func layoutSubviews() {
        super.layoutSubviews()

        updateBorder()
    }
}

// MARK: - UI Setup

extension PlanUpgradePromoView {

    private func setTheme() {
        backgroundColor = .clear

        // Container Styling (No border width here)
        promoContainer.do {
            $0.layer.cornerRadius = 12
            $0.layer.shadowColor = UIColor.planUpgradeSelectionShadow.cgColor
            $0.layer.shadowOpacity = 0.75
            $0.layer.shadowRadius = 15
            $0.layer.shadowOffset = CGSize(width: 0, height: 2)
            $0.clipsToBounds = false
            $0.layer.masksToBounds = false
        }

        promoContainerBackgroundView.do {
            $0.layer.masksToBounds = true
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 12
        }

        promoContainerOverlay.do {
            $0.backgroundColor = UIColor.planUpgradeSelectionHighlight.withAlphaComponent(0.1)
            $0.layer.cornerRadius = 12
        }

        promoTitleLabel.do {
            $0.text = "-"
            $0.font = UIFont.regular(textStyle: .subheadline)
            $0.textColor = .planUpgradeSelectionHighlight
        }

        promoPriceLabel.do {
            $0.text = "- - / -"
            $0.font = UIFont.bold(textStyle: .title3)
            $0.textColor = .planUpgradeSelectionHighlight
        }

        promoSubtitleLabel.do {
            $0.text = "- -"
            $0.font = UIFont.regular(textStyle: .subheadline)
            $0.numberOfLines = 0
            $0.textColor = .planUpgradeSelectionHighlight
        }

        promoDiscountLabelContainer.do {
            $0.backgroundColor = .planUpgradeSelectionHighlight
            $0.layer.cornerRadius = 4
        }

        promoDiscountLabel.do {
            $0.text = "\(TextsAsset.save.uppercased()) -%"
            $0.font = UIFont.bold(textStyle: .caption2)
            $0.textColor = .black
            $0.textAlignment = .center
        }
    }

    private func doLayout() {
        addSubview(promoContainer)

        promoContainer.addSubviews(
            [promoContainerBackgroundView, promoContainerOverlay, promoTitleLabel,
             promoPriceLabel, promoSubtitleLabel, promoDiscountLabelContainer])

        promoDiscountLabelContainer.addSubview(promoDiscountLabel)

        promoContainer.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.greaterThanOrEqualTo(80)
        }

        promoContainerBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        promoContainerOverlay.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        promoTitleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16)
        }

        promoPriceLabel.snp.makeConstraints {
            $0.top.equalTo(promoTitleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        promoSubtitleLabel.snp.makeConstraints {
            $0.bottom.leading.trailing.equalToSuperview().inset(16)
            $0.top.greaterThanOrEqualTo(promoPriceLabel.snp.bottom).offset(16)
        }

        promoDiscountLabelContainer.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-24)
            $0.top.equalToSuperview().inset(-8)
        }

        promoDiscountLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(2)
        }

        promoContainer.bringSubviewToFront(promoDiscountLabelContainer)
    }

    func populateSelectionTypes(discountedTier: WindscribeInAppProduct) {
        promoTitleLabel.text = discountedTier.planTitle
        promoPriceLabel.text = discountedTier.planLabel
        promoDiscountLabel.text = "\(TextsAsset.save.uppercased()) \(discountedTier.planDiscount)%"
        promoSubtitleLabel.attributedText = discountedTier.promoDescription
    }

    // Border Fix (Prevents Overlapping)
    private func updateBorder() {
        borderLayer.removeFromSuperlayer() // Remove old border if any

        borderLayer.do {
            $0.strokeColor = UIColor.planUpgradeSelectionHighlight.cgColor
            $0.fillColor = UIColor.clear.cgColor
            $0.lineWidth = 2
            $0.frame = promoContainer.bounds
            $0.path = UIBezierPath(roundedRect: promoContainer.bounds, cornerRadius: 12).cgPath
        }

        // Insert **behind** subviews so it will strike the discount
        promoContainerBackgroundView.layer.insertSublayer(borderLayer, at: 0)

        promoContainer.layer.shadowPath = UIBezierPath(roundedRect: promoContainer.bounds, cornerRadius: 12).cgPath
    }
}

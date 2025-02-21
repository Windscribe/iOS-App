//
//  PlanUgradeViewController+UI.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-03.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit

// MARK: - UI Setup

extension PlanUpgradeViewController {

    // MARK: Set Theme

    func setTheme() {
        setThemeNavigationBar()
        setThemeBackground()
        setThemeMainContentView()
        setThemeBenefitsSection()
        setThemePlanSelection()
        setThemeSubscribeButton()
        setThemeDeepNoteView()
        setThemeLegalContentView()
    }

    private func setThemeNavigationBar() {
        navigationController?.do {
            $0.navigationBar.isTranslucent = true
            $0.navigationBar.setBackgroundImage(UIImage(), for: .default)
            $0.navigationBar.shadowImage = UIImage()
        }
    }

    private func setThemeBackground() {
        view.addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.planUpgradeBackground

        containerStarBackground.do {
            $0.contentMode = isRegularSizeClass ? .scaleToFill : .scaleAspectFill
            $0.clipsToBounds = isRegularSizeClass ? true : false
            $0.image = UIImage(named: isRegularSizeClass ? "hero-stars-large" : "hero-stars")
        }

        backgroundView.addSubview(containerStarBackground)
    }

    private func setThemeMainContentView() {
        mainStackView.do {
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .fill
        }

        contentVerticalSpacing = isRegularSizeClass ? (isPortrait ? 64 : 32) : 24
        contentHorizontalSpacing = isRegularSizeClass ? 32 : 16
    }

    private func setThemeBenefitsSection() {
        benefitsStackView.do {
            $0.setBackgroundColor(.planUpgradeBackground)
            $0.axis = .vertical
            $0.spacing = isRegularSizeClass ? (isPortrait ? 24 : 18) : 12
            $0.alignment = .fill
            $0.distribution = .fill
        }
    }

    private func setThemePlanSelection() {
        planSelectionStackView.do {
            $0.axis = .vertical
            $0.alignment = .fill
            $0.distribution = .fill
        }
    }

    private func setThemeSubscribeButton() {
        subscribeButton.do {
            $0.setTitle(TextsAsset.UpgradeView.subscribe, for: .normal)
            $0.setTitleColor(.black, for: .normal)
            $0.titleLabel?.font = UIFont.bold(textStyle: .title3)
            $0.isEnabled = false
            $0.layer.cornerRadius = 24
            $0.layer.masksToBounds = true
        }
    }

    private func setThemeDeepNoteView() {
        subscriptionDetailsLabel.do {
            $0.text = TextsAsset.UpgradeView.details
            $0.font = UIFont.text(textStyle: .caption2)
            $0.adjustsFontForContentSizeCategory = true
            $0.lineBreakMode = .byWordWrapping
            $0.textColor = .whiteWithOpacity(opacity: 0.5)
            $0.textAlignment = .left
            $0.numberOfLines = 0
        }
    }

    private func setThemeLegalContentView() {
        legalTextContainerView.backgroundColor = .clear

        legalTextContentView.do {
            $0.backgroundColor = .clear

            let htmlString = "Windscribe <a href='https://windscribe.com/terms'>\(TextsAsset.UpgradeView.termsOfUse)</a> & <a href='https://windscribe.com/privacy'>\(TextsAsset.UpgradeView.privacyPolicy)</a>"
            if let htmlData = htmlString.data(using: .utf8) {
                $0.htmlText(htmlData: htmlData)
            }

            $0.linkTextAttributes = [.foregroundColor: UIColor.white, .underlineColor: UIColor.white]
            $0.isScrollEnabled = false
            $0.isEditable = false
            $0.font = UIFont.text(textStyle: .caption2)
            $0.textAlignment = .left
            $0.textColor = .whiteWithOpacity(opacity: 0.5)
            $0.adjustsFontForContentSizeCategory = true
            $0.textContainer.lineFragmentPadding = 0
        }
    }

    // MARK: Do Layout

    func doLayout() {
        layoutNavigationBar()
        layoutBackground()
        layoutMainContentView()

        layoutLogoView()
        layoutBenefitsSection()
        layoutSelectionPlanView()
        layoutSubscribeButton()
        layoutSubsriptionDeepNoteView()
        layoutLegalContentView()
    }

    private func layoutNavigationBar() {
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        closeButton.tintColor = UIColor.whiteWithOpacity(opacity: 0.8)

        closeButton.setTitleTextAttributes(
            [.font: UIFont.semiBold(textStyle: .title3)],
            for: .normal)
        navigationItem.leftBarButtonItem = closeButton

        let restoreButton = UIBarButtonItem(
            title: TextsAsset.UpgradeView.restore,
            style: .plain,
            target: self,
            action: #selector(restoreButtonTapped)
        )
        restoreButton.setTitleTextAttributes(
            [.font: UIFont.semiBold(textStyle: .subheadline),
             .foregroundColor: UIColor.whiteWithOpacity(opacity: 0.8)],
            for: .normal)
        navigationItem.rightBarButtonItem = restoreButton
    }

    private func layoutBackground() {
        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        containerStarBackground.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview().multipliedBy(isRegularSizeClass ? 0.3 : 0.4)
        }
    }

    private func layoutMainContentView() {
        view.addSubview(mainContentScrollView)
        mainContentScrollView.addSubview(mainStackView)

        mainContentScrollView.snp.remakeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
        }

        mainStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview() // Ensure horizontal scrolling is disabled
        }

        mainContentScrollView.alwaysBounceHorizontal = false
        mainContentScrollView.showsHorizontalScrollIndicator = false
    }

    private func layoutLogoView() {
        if let logoView = logoView {
            mainStackView.addArrangedSubview(logoView)
            mainStackView.setCustomSpacing(contentVerticalSpacing, after: logoView)
        }
    }

    private func layoutBenefitsSection() {
        benefitsStackView.removeAllArrangedSubviews()
        mainStackView.addArrangedSubview(benefitsStackView)
        mainStackView.setCustomSpacing(contentVerticalSpacing, after: benefitsStackView)

        benefitsStackView.addArrangedSubview(
            PlanUpgradeBenefitView(
                title: TextsAsset.UpgradeView.planBenefitUnlimitedTitle,
                subtitle: TextsAsset.UpgradeView.planBenefitUnlimitedDescription,
                imageName: "checkbox-terms"
            )
        )
        benefitsStackView.addArrangedSubview(
            PlanUpgradeBenefitView(
                title: TextsAsset.UpgradeView.planBenefitAllLocationsTitle,
                subtitle: TextsAsset.UpgradeView.planBenefitAllLocationsDescription,
                imageName: "checkbox-terms"
            )
        )
        benefitsStackView.addArrangedSubview(
            PlanUpgradeBenefitView(
                title: TextsAsset.UpgradeView.planBenefitSpeedSecurityTitle,
                subtitle: TextsAsset.UpgradeView.planBenefitSpeedSecurityDescription,
                imageName: "checkbox-terms"
            )
        )

        benefitsStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }
    }

    private func layoutSelectionPlanView() {
        planSelectionStackView.removeAllArrangedSubviews()
        mainStackView.addArrangedSubview(planSelectionStackView)

        if isPromotion {
            planSelectionStackView.addArrangedSubview(promoSelectionView)
        } else {
            planSelectionStackView.addArrangedSubview(planSelectionView)
        }

        mainStackView.setCustomSpacing(contentVerticalSpacing, after: planSelectionStackView)

        planSelectionStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }
    }

    private func layoutSubscribeButton() {
        mainStackView.addArrangedSubview(subscribeButton)
        mainStackView.setCustomSpacing(contentVerticalSpacing, after: subscribeButton)

        subscribeButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
            $0.height.equalTo(50)
        }
    }

    private func layoutSubsriptionDeepNoteView() {
        mainStackView.addArrangedSubview(subscriptionDetailsLabel)
        mainStackView.setCustomSpacing(8, after: legalTextContainerView)

        subscriptionDetailsLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }
    }

    private func layoutLegalContentView() {
        legalTextContainerView.addSubview(legalTextContentView)

        legalTextContentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        mainStackView.addArrangedSubview(legalTextContainerView)

        legalTextContainerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }
    }

    func updateViewSpacing() {
        guard isRegularSizeClass else { return }

        contentVerticalSpacing = isRegularSizeClass ? (isPortrait ? 64 : 32) : 24
        contentHorizontalSpacing = isRegularSizeClass ? 32 : 16

        benefitsStackView.spacing = isRegularSizeClass ? (isPortrait ? 24 : 18) : 12

        guard let logoView = logoView else { return }

        mainStackView.do {
            $0.setCustomSpacing(contentVerticalSpacing, after: logoView)
            $0.setCustomSpacing(contentVerticalSpacing, after: benefitsStackView)
            $0.setCustomSpacing(contentVerticalSpacing, after: planSelectionStackView)
            $0.setCustomSpacing(contentVerticalSpacing, after: subscribeButton)
        }

        benefitsStackView.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }

        planSelectionStackView.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }

        subscribeButton.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }

        subscriptionDetailsLabel.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }

        legalTextContainerView.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }

        containerStarBackground.snp.remakeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalToSuperview().multipliedBy(isRegularSizeClass ? 0.3 : 0.4)
        }
    }
}

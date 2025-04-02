//
//  PlanUpgradeSelectionView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-03.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import SnapKit

class PlanUpgradeSelectionView: UIView {

    // MARK: UI Components

    private let containerStackView = UIStackView()

    private let monthlyContainer = UIView()
    private let monthlyContainerBackgroundView = PlanUpgradeStarsBackgroundView()
    private let monthlyContainerOverlay = UIView()
    private let monthlyTitleLabel = UILabel()
    private let monthlyPriceLabel = UILabel()
    private let monthlySubtitleLabel = UILabel()
    private let monthlyCheckmark = UIImageView()

    private let yearlyContainer = UIView()
    private let yearlyContainerBackgroundView = PlanUpgradeStarsBackgroundView()
    private let yearlyContainerOverlay = UIView()
    private let yearlyTitleLabel = UILabel()
    private let yearlyPriceLabel = UILabel()
    private let yearlySubtitleLabel = UILabel()
    private let yearlyCheckmark = UIImageView()
    private let yearlyDiscountLabel = UILabel()
    private let yearlyDiscountLabelContainer = UIView()

    private let disposeBag = DisposeBag()

    // Reactive property for plan selection
    var selectedPlan: PublishSubject<String?> = PublishSubject()
    var monthlyPlanID: String?
    var yearlyPlanID: String?

    // MARK: Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)

        setTheme()
        doLayout()

        setupBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup Bindings

    private func setupBindings() {
        let tapGestureMonthly = UITapGestureRecognizer()
        let tapGestureYearly = UITapGestureRecognizer()

        monthlyContainer.addGestureRecognizer(tapGestureMonthly)
        yearlyContainer.addGestureRecognizer(tapGestureYearly)

        tapGestureMonthly.rx.event
            .bind { [weak self] _ in
                self?.updateSelection(to: .monthly, planID: self?.monthlyPlanID)
            }
            .disposed(by: disposeBag)

        tapGestureYearly.rx.event
            .bind { [weak self] _ in
                self?.updateSelection(to: .yearly, planID: self?.yearlyPlanID)
            }
            .disposed(by: disposeBag)
    }

    // MARK: Update - Populate Selection

    private func updateSelection(to plan: PlanUpgradeType, planID: String?) {
        if let defaultPlanID = planID {
            selectedPlan.onNext(defaultPlanID)
        }

        let isMonthlySelected = plan == .monthly

        monthlyContainer.layer.borderWidth = isMonthlySelected ? 2 : 1
        monthlyContainer.layer.borderColor = isMonthlySelected
            ? UIColor.planUpgradeSelectionHighlight.cgColor
            : UIColor.white.withAlphaComponent(0.5).cgColor
        monthlyContainer.layer.shadowOpacity = isMonthlySelected ? 0.75 : 0
        monthlyContainerBackgroundView.isHidden = !isMonthlySelected
        monthlyContainerOverlay.isHidden = !isMonthlySelected
        monthlyCheckmark.image =
            isMonthlySelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle")
        monthlyCheckmark.tintColor = isMonthlySelected ? .planUpgradeSelectionHighlight : .white
        monthlyTitleLabel.textColor = isMonthlySelected ? .planUpgradeSelectionHighlight : .white
        monthlyPriceLabel.textColor = isMonthlySelected ? .planUpgradeSelectionHighlight : .white
        monthlySubtitleLabel.textColor = isMonthlySelected ? .planUpgradeSelectionHighlight : .white

        yearlyContainer.layer.borderColor = isMonthlySelected
            ? UIColor.white.withAlphaComponent(0.5).cgColor
            :  UIColor.planUpgradeSelectionHighlight.cgColor
        yearlyContainer.layer.borderWidth = isMonthlySelected ? 1 : 2
        yearlyContainer.layer.shadowOpacity = isMonthlySelected ? 0 : 0.75
        yearlyContainerBackgroundView.isHidden = isMonthlySelected
        yearlyContainerOverlay.isHidden = isMonthlySelected
        yearlyCheckmark.image =
            isMonthlySelected ? UIImage(systemName: "circle") : UIImage(systemName: "checkmark.circle.fill")
        yearlyCheckmark.tintColor = isMonthlySelected ? .white : .planUpgradeSelectionHighlight
        yearlyTitleLabel.textColor = isMonthlySelected ? .white : .planUpgradeSelectionHighlight
        yearlyPriceLabel.textColor = isMonthlySelected ? .white : .planUpgradeSelectionHighlight
        yearlySubtitleLabel.textColor = isMonthlySelected ? .white : .planUpgradeSelectionHighlight
        yearlyDiscountLabelContainer.backgroundColor = isMonthlySelected ? .white : .planUpgradeSelectionHighlight
    }

    func populateSelectionTypes(monthlyTier: WindscribeInAppProduct, yearlyTier: WindscribeInAppProduct) {
        monthlyPlanID = monthlyTier.extId
        yearlyPlanID = yearlyTier.extId

        monthlyTitleLabel.text = monthlyTier.planTitle
        monthlyPriceLabel.text = monthlyTier.planPrice
        monthlySubtitleLabel.text = monthlyTier.planDescription

        yearlyTitleLabel.text = yearlyTier.planTitle
        yearlyPriceLabel.text = yearlyTier.planPrice
        yearlySubtitleLabel.text = yearlyTier.planDescription
        yearlyDiscountLabel.text =
            calculateSavingsPercentage(monthly: monthlyTier.planProductPrice, yearly: yearlyTier.planProductPrice)
    }

    private func calculateSavingsPercentage(monthly: NSDecimalNumber, yearly: NSDecimalNumber) -> String {
        // Multiply monthly price by 12 to get full-year cost
        let fullYearCost = monthly.multiplying(by: NSDecimalNumber(value: 12))

        // Divide yearly cost by full-year cost and multiply by 100
        let percentageOfYearly = yearly.dividing(by: fullYearCost).multiplying(by: NSDecimalNumber(value: 100))

        // Calculate savings percentage
        let savingsPercentage = NSDecimalNumber(value: 100).subtracting(percentageOfYearly)

        let savingsInt = savingsPercentage.rounding(accordingToBehavior: nil).intValue

        return "-\(savingsInt)%"
    }
}

// MARK: - UI setup

extension PlanUpgradeSelectionView {

    // MARK: Set Theme

    private func setTheme() {
        containerStackView.do {
            $0.axis = .horizontal
            $0.spacing = 16
            $0.alignment = .fill
            $0.distribution = .fillEqually
            $0.clipsToBounds = false // Important for shadows
        }

        // Configure Monthly Container
        configureContainerTheme(
            container: monthlyContainer,
            containerBackground: monthlyContainerBackgroundView,
            containerOverlay: monthlyContainerOverlay,
            titleLabel: monthlyTitleLabel,
            priceLabel: monthlyPriceLabel,
            subtitleLabel: monthlySubtitleLabel,
            checkmark: monthlyCheckmark,
            discountLabel: nil,
            discountLabelContainer: nil,
            title: "-",
            price: "- -",
            subtitle: "- -",
            isSelected: true
        )

        // Configure Yearly Container with Discount
        configureContainerTheme(
            container: yearlyContainer,
            containerBackground: yearlyContainerBackgroundView,
            containerOverlay: yearlyContainerOverlay,
            titleLabel: yearlyTitleLabel,
            priceLabel: yearlyPriceLabel,
            subtitleLabel: yearlySubtitleLabel,
            checkmark: yearlyCheckmark,
            discountLabel: yearlyDiscountLabel,
            discountLabelContainer: yearlyDiscountLabelContainer,
            title: "-",
            price: "- -",
            subtitle: "-/-, - -",
            isSelected: false
        )
    }

    // MARK: Configure Container

    private func configureContainerTheme(
        container: UIView,
        containerBackground: PlanUpgradeStarsBackgroundView,
        containerOverlay: UIView,
        titleLabel: UILabel,
        priceLabel: UILabel,
        subtitleLabel: UILabel,
        checkmark: UIImageView,
        discountLabel: UILabel?,
        discountLabelContainer: UIView?,
        title: String,
        price: String,
        subtitle: String,
        isSelected: Bool
    ) {
        // Box Styling
        container.do {
            $0.layer.cornerRadius = 12
            $0.layer.borderWidth = isSelected ? 2 : 1
            $0.layer.borderColor = isSelected
                ? UIColor.planUpgradeSelectionHighlight.cgColor : UIColor.white.withAlphaComponent(0.5).cgColor

            $0.layer.shadowColor = UIColor.planUpgradeSelectionShadow.cgColor
            $0.layer.shadowOpacity = isSelected ? 0.75 : 0
            $0.layer.shadowRadius = 15
            $0.layer.shadowOffset = CGSize(width: 0, height: 2)

            $0.isUserInteractionEnabled = true
            $0.clipsToBounds = false // Ensure the shadow isn't clipped
            $0.layer.masksToBounds = false
        }

        containerBackground.do {
            $0.isHidden = !isSelected
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 12
        }

        containerOverlay.do {
            $0.backgroundColor = UIColor.planUpgradeSelectionHighlight.withAlphaComponent(0.1)
            $0.isHidden = !isSelected
            $0.layer.cornerRadius = 12
        }

        titleLabel.do {
            $0.text = title
            $0.font = UIFont.regular(textStyle: .subheadline)
            $0.adjustsFontForContentSizeCategory = true
            $0.textColor = isSelected ? .planUpgradeSelectionHighlight : .white
            $0.setContentHuggingPriority(.required, for: .horizontal)
        }

        priceLabel.do {
            $0.text = price
            $0.font = UIFont.bold(textStyle: .title3)
            $0.adjustsFontForContentSizeCategory = true
            $0.textColor = isSelected ? .planUpgradeSelectionHighlight : .white
        }

        subtitleLabel.do {
            $0.text = subtitle
            $0.font = UIFont.regular(textStyle: .subheadline)
            $0.adjustsFontForContentSizeCategory = true
            $0.textColor = isSelected ? .planUpgradeSelectionHighlight : UIColor.whiteWithOpacity(opacity: 0.7)
            $0.numberOfLines = 0
        }

        checkmark.do {
            $0.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            $0.tintColor = isSelected ? .planUpgradeSelectionHighlight : .white
        }

        guard let discountLabel = discountLabel, let discountLabelContainer = discountLabelContainer else {
            return
        }

        discountLabelContainer.do {
            $0.backgroundColor = .white
            $0.layer.cornerRadius = 4
            $0.layer.masksToBounds = true
        }

        discountLabel.do {
            $0.text = "-%"
            $0.font = UIFont.semiBold(textStyle: .caption2)
            $0.textColor = .black
            $0.textAlignment = .center
        }
    }

    // MARK: Do Layout

    private func doLayout() {
        containerStackView.addArrangedSubviews([monthlyContainer, yearlyContainer])
        addSubview(containerStackView)

        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(80)
        }

        configureContainerLayout(
            container: monthlyContainer,
            containerBackground: monthlyContainerBackgroundView,
            containerOverlay: monthlyContainerOverlay,
            titleLabel: monthlyTitleLabel,
            priceLabel: monthlyPriceLabel,
            subtitleLabel: monthlySubtitleLabel,
            checkmark: monthlyCheckmark,
            discountLabel: nil,
            discountLabelContainer: nil
        )

        configureContainerLayout(
            container: yearlyContainer,
            containerBackground: yearlyContainerBackgroundView,
            containerOverlay: yearlyContainerOverlay,
            titleLabel: yearlyTitleLabel,
            priceLabel: yearlyPriceLabel,
            subtitleLabel: yearlySubtitleLabel,
            checkmark: yearlyCheckmark,
            discountLabel: yearlyDiscountLabel,
            discountLabelContainer: yearlyDiscountLabelContainer
        )
    }

    private func configureContainerLayout(
        container: UIView,
        containerBackground: PlanUpgradeStarsBackgroundView,
        containerOverlay: UIView,
        titleLabel: UILabel,
        priceLabel: UILabel,
        subtitleLabel: UILabel,
        checkmark: UIImageView,
        discountLabel: UILabel?,
        discountLabelContainer: UIView?
    ) {
        container.addSubview(containerBackground)

        containerBackground.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        container.addSubview(containerOverlay)

        containerOverlay.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        container.addSubviews([titleLabel, priceLabel, subtitleLabel, checkmark])

        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
        }

        priceLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(12)
        }

        subtitleLabel.snp.makeConstraints {
            $0.bottom.leading.trailing.equalToSuperview().inset(12)
            $0.top.greaterThanOrEqualTo(priceLabel.snp.bottom).offset(16)
        }

        checkmark.snp.makeConstraints {
            $0.trailing.top.equalToSuperview().inset(12)
            $0.width.height.equalTo(20)
        }

        guard let discountLabel = discountLabel, let discountLabelContainer = discountLabelContainer else {
            return
        }

        discountLabelContainer.addSubview(discountLabel)

        discountLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(2)
        }

        container.addSubview(discountLabelContainer)

        discountLabelContainer.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(12)
            $0.top.equalToSuperview().inset(12)
        }
    }
}

//
//  UpgradeViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-28.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import ExpyTableView
import Swinject
import UIKit

extension UpgradeViewController {
    func addPricesViews() {
        firstPlanRadioButton = ImageButton()
        firstPlanRadioButton.addTarget(self, action: #selector(makeFirstPlanSelected), for: .touchUpInside)

        firstPlanOptionButton = UIButton()
        if UIDevice.current.isIphone5orLess() {
            firstPlanOptionButton.titleLabel?.font = UIFont.bold(size: 12)
        } else {
            firstPlanOptionButton.titleLabel?.font = UIFont.bold(size: 14)
        }
        firstPlanOptionButton.addTarget(self, action: #selector(makeFirstPlanSelected), for: .touchUpInside)

        secondPlanRadioButtton = ImageButton()
        secondPlanRadioButtton.addTarget(self, action: #selector(makeSecondPlanSelected), for: .touchUpInside)

        secondPlanOptionButton = UIButton()
        if UIDevice.current.isIphone5orLess() {
            secondPlanOptionButton.titleLabel?.font = UIFont.bold(size: 12)
        } else {
            secondPlanOptionButton.titleLabel?.font = UIFont.bold(size: 14)
        }
        secondPlanOptionButton.addTarget(self, action: #selector(makeSecondPlanSelected), for: .touchUpInside)

        pricesView = UIView()
        pricesView.backgroundColor = .clear
        pricesView.addSubview(firstPlanRadioButton)
        pricesView.addSubview(firstPlanOptionButton)
        pricesView.addSubview(secondPlanRadioButtton)
        pricesView.addSubview(secondPlanOptionButton)
    }

    func layoutPricesViews() {
        secondPlanOptionButton.setTitleColor(UIColor.seaGreen, for: .normal)
        secondPlanRadioButtton.setImage(UIImage(named: ImagesAsset.radioPriceSelected), for: .normal)

        firstPlanOptionButton.setTitleColor(UIColor.whiteWithOpacity(opacity: 0.55), for: .normal)
        firstPlanRadioButton.setImage(UIImage(named: ImagesAsset.radioPriceNotSelected), for: .normal)

        pricesView.translatesAutoresizingMaskIntoConstraints = false
        firstPlanRadioButton.translatesAutoresizingMaskIntoConstraints = false
        firstPlanOptionButton.translatesAutoresizingMaskIntoConstraints = false
        secondPlanRadioButtton.translatesAutoresizingMaskIntoConstraints = false
        secondPlanOptionButton.translatesAutoresizingMaskIntoConstraints = false

        pricesView.addConstraints([
            .init(item: firstPlanRadioButton as Any, attribute: .left, relatedBy: .equal, toItem: pricesView, attribute: .left, multiplier: 1, constant: 0),
            .init(item: firstPlanRadioButton as Any, attribute: .centerY, relatedBy: .equal, toItem: pricesView, attribute: .centerY, multiplier: 1, constant: 0),
            firstPlanRadioButton.widthAnchor.constraint(equalToConstant: 16),
            firstPlanRadioButton.heightAnchor.constraint(equalToConstant: 16),
        ])

        pricesView.addConstraints([
            .init(item: firstPlanOptionButton as Any, attribute: .top, relatedBy: .equal, toItem: pricesView, attribute: .top, multiplier: 1, constant: 16),
            .init(item: firstPlanOptionButton as Any, attribute: .bottom, relatedBy: .equal, toItem: pricesView, attribute: .bottom, multiplier: 1, constant: -16),
            .init(item: firstPlanOptionButton as Any, attribute: .left, relatedBy: .equal, toItem: firstPlanRadioButton, attribute: .right, multiplier: 1, constant: 8),
        ])

        pricesView.addConstraints([
            .init(item: secondPlanRadioButtton as Any, attribute: .centerY, relatedBy: .equal, toItem: pricesView, attribute: .centerY, multiplier: 1, constant: 0),
            .init(item: secondPlanRadioButtton as Any, attribute: .right, relatedBy: .equal, toItem: secondPlanOptionButton, attribute: .left, multiplier: 1, constant: -8),
            secondPlanRadioButtton.widthAnchor.constraint(equalToConstant: 16),
            secondPlanRadioButtton.heightAnchor.constraint(equalToConstant: 16),
        ])

        pricesView.addConstraints([
            .init(item: secondPlanOptionButton as Any, attribute: .top, relatedBy: .equal, toItem: pricesView, attribute: .top, multiplier: 1, constant: 16),
            .init(item: secondPlanOptionButton as Any, attribute: .bottom, relatedBy: .equal, toItem: pricesView, attribute: .bottom, multiplier: 1, constant: -16),
            .init(item: secondPlanOptionButton as Any, attribute: .right, relatedBy: .equal, toItem: pricesView, attribute: .right, multiplier: 1, constant: 0),
        ])
    }

    func layoutDiscountViews() {
        discountView.translatesAutoresizingMaskIntoConstraints = false
        discountLabel.translatesAutoresizingMaskIntoConstraints = false
        discountPercentLabel.translatesAutoresizingMaskIntoConstraints = false
        discountSeparateView.translatesAutoresizingMaskIntoConstraints = false

        discountView.addConstraints([
            .init(item: discountLabel as Any, attribute: .top, relatedBy: .equal, toItem: discountView, attribute: .top, multiplier: 1, constant: 16),
            .init(item: discountLabel as Any, attribute: .bottom, relatedBy: .equal, toItem: discountView, attribute: .bottom, multiplier: 1, constant: -16),
            .init(item: discountLabel as Any, attribute: .right, relatedBy: .equal, toItem: discountSeparateView, attribute: .left, multiplier: 1, constant: -16),
        ])

        discountView.addConstraints([
            discountSeparateView.centerXAnchor.constraint(equalTo: discountView.centerXAnchor),
            discountSeparateView.centerYAnchor.constraint(equalTo: discountView.centerYAnchor),
            discountSeparateView.heightAnchor.constraint(equalToConstant: 20),
            discountSeparateView.widthAnchor.constraint(equalToConstant: 2),
        ])

        discountView.addConstraints([
            .init(item: discountPercentLabel as Any, attribute: .left, relatedBy: .equal, toItem: discountSeparateView, attribute: .right, multiplier: 1, constant: 16),
            .init(item: discountPercentLabel as Any, attribute: .top, relatedBy: .equal, toItem: discountView, attribute: .top, multiplier: 1, constant: 16),
            .init(item: discountPercentLabel as Any, attribute: .bottom, relatedBy: .equal, toItem: discountView, attribute: .bottom, multiplier: 1, constant: -16),
        ])
    }

    func layoutPromoViews() {
        promoView.translatesAutoresizingMaskIntoConstraints = false
        promoLabel.translatesAutoresizingMaskIntoConstraints = false
        promoIconImageView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addConstraints([
            .init(item: promoView as Any, attribute: .top, relatedBy: .equal, toItem: proView, attribute: .top, multiplier: 1, constant: 0),
            .init(item: promoView as Any, attribute: .right, relatedBy: .equal, toItem: proView, attribute: .right, multiplier: 1, constant: 0),
        ])

        scrollView.addConstraints([
            .init(item: promoLabel as Any, attribute: .top, relatedBy: .equal, toItem: promoView, attribute: .top, multiplier: 1, constant: 8),
            .init(item: promoLabel as Any, attribute: .left, relatedBy: .equal, toItem: promoIconImageView, attribute: .right, multiplier: 1, constant: 8),
            .init(item: promoLabel as Any, attribute: .right, relatedBy: .equal, toItem: promoView, attribute: .right, multiplier: 1, constant: -8),
            .init(item: promoLabel as Any, attribute: .bottom, relatedBy: .equal, toItem: promoView, attribute: .bottom, multiplier: 1, constant: -8),
        ])

        scrollView.addConstraints([
            .init(item: promoIconImageView as Any, attribute: .left, relatedBy: .equal, toItem: promoView, attribute: .left, multiplier: 1, constant: 10),
            .init(item: promoIconImageView as Any, attribute: .centerY, relatedBy: .equal, toItem: promoView, attribute: .centerY, multiplier: 1, constant: 0),
            promoIconImageView.heightAnchor.constraint(equalToConstant: 12),
            promoIconImageView.widthAnchor.constraint(equalToConstant: 12),
        ])
    }

    func addPromoView() {
        promoView = UIView()
        promoView.clipsToBounds = true
        promoView.backgroundColor = UIColor.seaGreen
        promoView.layer.opacity = 0.1
        promoView.isHidden = true
        scrollView.addSubview(promoView)

        promoLabel = UILabel()
        promoLabel.font = UIFont.text(size: 14)
        promoLabel.textColor = UIColor.seaGreen
        scrollView.addSubview(promoLabel)

        promoIconImageView = UIImageView()
        promoIconImageView.image = UIImage(named: ImagesAsset.greenCheckMark)
        promoIconImageView.isHidden = true
        scrollView.addSubview(promoIconImageView)
    }

    func addViews() {
        scrollView = UIScrollView()
        if UIDevice.current.isIphone5orLess() {
            scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height + 100)
        } else {
            scrollView.isScrollEnabled = false
            scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
        view.addSubview(scrollView)

        proView = UIView()
        proView.backgroundColor = UIColor.whiteWithOpacity(opacity: 0.05)
        proView.layer.cornerRadius = 6
        proView.clipsToBounds = true
        scrollView.addSubview(proView)

        proLabel = UILabel()
        proLabel.text = TextsAsset.proSubscription
        proLabel.font = UIFont.bold(size: 24)
        proLabel.textAlignment = .left
        proLabel.textColor = UIColor.white
        scrollView.addSubview(proLabel)

        pricingLabel = UILabel()
        pricingLabel.text = TextsAsset.UpgradeView.pricing.uppercased()
        pricingLabel.font = UIFont.bold(size: 12)
        pricingLabel.textAlignment = .left
        pricingLabel.textColor = UIColor.white
        pricingLabel.layer.opacity = 0.5
        pricingLabel.setLetterSpacing(value: 2)
        scrollView.addSubview(pricingLabel)

        firstPlanRadioButton = ImageButton()
        firstPlanRadioButton.addTarget(self, action: #selector(makeFirstPlanSelected), for: .touchUpInside)
        scrollView.addSubview(firstPlanRadioButton)

        firstPlanOptionButton = UIButton()
        if UIDevice.current.isIphone5orLess() {
            firstPlanOptionButton.titleLabel?.font = UIFont.bold(size: 12)
        } else {
            firstPlanOptionButton.titleLabel?.font = UIFont.bold(size: 14)
        }
        firstPlanOptionButton.addTarget(self, action: #selector(makeFirstPlanSelected), for: .touchUpInside)
        scrollView.addSubview(firstPlanOptionButton)

        secondPlanRadioButtton = ImageButton()
        secondPlanRadioButtton.addTarget(self, action: #selector(makeSecondPlanSelected), for: .touchUpInside)
        scrollView.addSubview(secondPlanRadioButtton)

        secondPlanOptionButton = UIButton()
        if UIDevice.current.isIphone5orLess() {
            secondPlanOptionButton.titleLabel?.font = UIFont.bold(size: 12)
        } else {
            secondPlanOptionButton.titleLabel?.font = UIFont.bold(size: 14)
        }
        secondPlanOptionButton.addTarget(self, action: #selector(makeSecondPlanSelected), for: .touchUpInside)
        scrollView.addSubview(secondPlanOptionButton)

        benefistsLabel = UILabel()
        benefistsLabel.text = TextsAsset.UpgradeView.benefits.uppercased()
        benefistsLabel.font = UIFont.bold(size: 12)
        benefistsLabel.textAlignment = .left
        benefistsLabel.textColor = UIColor.white
        benefistsLabel.layer.opacity = 0.5
        benefistsLabel.setLetterSpacing(value: 2)
        scrollView.addSubview(benefistsLabel)

        firstIcon = UIImageView()
        firstIcon.image = UIImage(named: ImagesAsset.greenCheckMark)
        scrollView.addSubview(firstIcon)

        firstLabel = UILabel()
        firstLabel.text = TextsAsset.UpgradeView.unlimitedData
        firstLabel.font = UIFont.text(size: 14)
        firstLabel.textColor = UIColor.white
        scrollView.addSubview(firstLabel)

        firstInfoButton = ImageButton()
        firstInfoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        firstInfoButton.setImage(UIImage(named: ImagesAsset.upgradeInfo), for: .normal)
        scrollView.addSubview(firstInfoButton)

        firstSeperator = UIView()
        firstSeperator.backgroundColor = UIColor.white
        firstSeperator.layer.opacity = 0.15
        scrollView.addSubview(firstSeperator)

        secondIcon = UIImageView()
        secondIcon.image = UIImage(named: ImagesAsset.greenCheckMark)
        scrollView.addSubview(secondIcon)

        secondLabel = UILabel()
        secondLabel.text = TextsAsset.UpgradeView.allLocations
        secondLabel.font = UIFont.text(size: 14)
        secondLabel.textColor = UIColor.white
        scrollView.addSubview(secondLabel)

        secondInfoButton = ImageButton()
        secondInfoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        secondInfoButton.setImage(UIImage(named: ImagesAsset.upgradeInfo), for: .normal)
        scrollView.addSubview(secondInfoButton)

        secondSeperator = UIView()
        secondSeperator.backgroundColor = UIColor.white
        secondSeperator.layer.opacity = 0.15
        scrollView.addSubview(secondSeperator)

        thirdIcon = UIImageView()
        thirdIcon.image = UIImage(named: ImagesAsset.greenCheckMark)
        scrollView.addSubview(thirdIcon)

        thirdLabel = UILabel()
        thirdLabel.text = TextsAsset.UpgradeView.robert
        thirdLabel.font = UIFont.text(size: 14)
        thirdLabel.textColor = UIColor.white
        scrollView.addSubview(thirdLabel)

        thirdInfoButton = ImageButton()
        thirdInfoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        thirdInfoButton.setImage(UIImage(named: ImagesAsset.upgradeInfo), for: .normal)
        scrollView.addSubview(thirdInfoButton)

        thirdSeperator = UIView()
        thirdSeperator.backgroundColor = UIColor.white
        thirdSeperator.layer.opacity = 0.15
        scrollView.addSubview(thirdSeperator)

        iapDescriptionLabel = UILabel()
        iapDescriptionLabel.text = TextsAsset.UpgradeView.iAPDescription
        iapDescriptionLabel.numberOfLines = 0
        iapDescriptionLabel.font = UIFont.text(size: 8)
        iapDescriptionLabel.layer.opacity = 0.5
        iapDescriptionLabel.textAlignment = .left
        iapDescriptionLabel.textColor = UIColor.white
        scrollView.addSubview(iapDescriptionLabel)

        legalTextView = UITextView()
        legalTextView.backgroundColor = UIColor.clear
        let htmlString = "Windscribe <a href='https://windscribe.com/terms'>Terms of Use</a> & <a href='https://windscribe.com/privacy'>Privacy Policy</a>"
        if let htmlData = htmlString.data(using: .utf8) {
            legalTextView.htmlText(htmlData: htmlData)
        }
        legalTextView.linkTextAttributes = [.foregroundColor: UIColor.white, .underlineColor: UIColor.clear]
        legalTextView.isScrollEnabled = false
        legalTextView.isEditable = false
        legalTextView.font = UIFont.text(size: 8)
        legalTextView.textAlignment = .left
        legalTextView.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
        scrollView.addSubview(legalTextView)

        continuePayButton = UIButton()
        continuePayButton.setTitleColor(UIColor.black, for: .normal)
        continuePayButton.titleLabel?.font = UIFont.text(size: 16)
        continuePayButton.addTarget(self, action: #selector(continuePayButtonTapped), for: .touchUpInside)
        continuePayButton.layer.cornerRadius = 26
        continuePayButton.clipsToBounds = true
        continuePayButton.backgroundColor = UIColor.seaGreen
        continuePayButton.setTitle(TextsAsset.continue, for: .normal)
        scrollView.addSubview(continuePayButton)

        continueFreeButton = UIButton()
        continueFreeButton.titleLabel?.font = UIFont.text(size: 14)
        continueFreeButton.addTarget(self, action: #selector(continueFreeButtonTapped), for: .touchUpInside)
        let attributedTitle = NSMutableAttributedString(string: "\(TextsAsset.continue) \(TextsAsset.UpgradeView.continueFree10GB)")
        attributedTitle.addAttribute(.font, value: UIFont.bold(size: 14),
                                     range: NSRange(location: 0,
                                                    length: TextsAsset.continue.count))
        attributedTitle.addAttribute(.foregroundColor, value: UIColor.whiteWithOpacity(opacity: 0.5), range: NSRange(location: 0, length: attributedTitle.length))
        continueFreeButton.setAttributedTitle(attributedTitle, for: .normal)
        scrollView.addSubview(continueFreeButton)

        restoreButton = UIButton(type: .system)
        restoreButton.setTitle(TextsAsset.UpgradeView.restorePurchases, for: .normal)
        restoreButton.titleLabel?.font = UIFont.text(size: 12)
        restoreButton.setTitleColor(UIColor.white, for: .normal)
        restoreButton.layer.opacity = 0.5
        restoreButton.addTarget(self, action: #selector(restoreButtonTapped), for: .touchUpInside)
        scrollView.addSubview(restoreButton)

        addPricesViews()
        addDiscountViews()
        addPromoView()

        pricesStackView = UIStackView()
        pricesStackView.axis = .vertical
        scrollView.addSubview(pricesStackView)
        pricesStackView.addArrangedSubview(pricesView)
        pricesStackView.addArrangedSubview(discountView)

        pricesView.isHidden = true
        discountView.isHidden = true
    }

    func addDiscountViews() {
        discountLabel = UILabel()
        discountLabel.font = UIFont.bold(size: 14)
        discountLabel.textAlignment = .right
        discountLabel.textColor = UIColor.seaGreen

        discountPercentLabel = UILabel()
        discountPercentLabel.font = UIFont.text(size: 14)
        discountPercentLabel.textColor = UIColor.seaGreen
        discountPercentLabel.textAlignment = .left

        discountSeparateView = UIView()
        discountSeparateView.backgroundColor = UIColor.whiteWithOpacity(opacity: 0.15)

        discountView = UIView()
        discountView.backgroundColor = .clear
        discountView.addSubview(discountLabel)
        discountView.addSubview(discountSeparateView)
        discountView.addSubview(discountPercentLabel)
    }

    func addAutoLayoutConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        proView.translatesAutoresizingMaskIntoConstraints = false
        proLabel.translatesAutoresizingMaskIntoConstraints = false
        pricingLabel.translatesAutoresizingMaskIntoConstraints = false
        firstPlanRadioButton.translatesAutoresizingMaskIntoConstraints = false
        firstPlanOptionButton.translatesAutoresizingMaskIntoConstraints = false
        secondPlanRadioButtton.translatesAutoresizingMaskIntoConstraints = false
        secondPlanOptionButton.translatesAutoresizingMaskIntoConstraints = false
        benefistsLabel.translatesAutoresizingMaskIntoConstraints = false
        firstIcon.translatesAutoresizingMaskIntoConstraints = false
        firstLabel.translatesAutoresizingMaskIntoConstraints = false
        firstInfoButton.translatesAutoresizingMaskIntoConstraints = false
        firstSeperator.translatesAutoresizingMaskIntoConstraints = false
        secondIcon.translatesAutoresizingMaskIntoConstraints = false
        secondLabel.translatesAutoresizingMaskIntoConstraints = false
        secondInfoButton.translatesAutoresizingMaskIntoConstraints = false
        secondSeperator.translatesAutoresizingMaskIntoConstraints = false
        thirdIcon.translatesAutoresizingMaskIntoConstraints = false
        thirdLabel.translatesAutoresizingMaskIntoConstraints = false
        thirdInfoButton.translatesAutoresizingMaskIntoConstraints = false
        thirdSeperator.translatesAutoresizingMaskIntoConstraints = false
        iapDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        legalTextView.translatesAutoresizingMaskIntoConstraints = false
        continuePayButton.translatesAutoresizingMaskIntoConstraints = false
        continueFreeButton.translatesAutoresizingMaskIntoConstraints = false
        restoreButton.translatesAutoresizingMaskIntoConstraints = false
        pricesStackView.translatesAutoresizingMaskIntoConstraints = false

        layoutPricesViews()
        layoutDiscountViews()
        layoutPromoViews()

        view.addConstraints([
            NSLayoutConstraint(item: scrollView as Any, attribute: .top, relatedBy: .equal, toItem: backButton, attribute: .bottom, multiplier: 1.0, constant: 12),
            NSLayoutConstraint(item: scrollView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: scrollView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: scrollView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: proView as Any, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: proView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: proView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: proView as Any, attribute: .bottom, relatedBy: .equal, toItem: legalTextView, attribute: .bottom, multiplier: 1.0, constant: 24),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: proLabel as Any, attribute: .left, relatedBy: .equal, toItem: proView, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: proLabel as Any, attribute: .top, relatedBy: .equal, toItem: proView, attribute: .top, multiplier: 1.0, constant: 16),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: pricingLabel as Any, attribute: .left, relatedBy: .equal, toItem: proLabel, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: pricingLabel as Any, attribute: .top, relatedBy: .equal, toItem: proLabel, attribute: .bottom, multiplier: 1.0, constant: 8),
        ])

        view.addConstraints([
            .init(item: pricesStackView as Any, attribute: .top, relatedBy: .equal, toItem: pricingLabel, attribute: .bottom, multiplier: 1, constant: 0),
            .init(item: pricesStackView as Any, attribute: .left, relatedBy: .equal, toItem: scrollView, attribute: .left, multiplier: 1, constant: 40),
            .init(item: pricesStackView as Any, attribute: .right, relatedBy: .equal, toItem: scrollView, attribute: .right, multiplier: 1, constant: -40),
            pricesStackView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 80),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: benefistsLabel as Any, attribute: .left, relatedBy: .equal, toItem: proLabel, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: benefistsLabel as Any, attribute: .top, relatedBy: .equal, toItem: pricesStackView, attribute: .bottom, multiplier: 1.0, constant: 0),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: firstIcon as Any, attribute: .top, relatedBy: .equal, toItem: benefistsLabel, attribute: .bottom, multiplier: 1.0, constant: 17),
            NSLayoutConstraint(item: firstIcon as Any, attribute: .left, relatedBy: .equal, toItem: proLabel, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: firstIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: firstIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: firstLabel as Any, attribute: .top, relatedBy: .equal, toItem: firstIcon, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: firstLabel as Any, attribute: .left, relatedBy: .equal, toItem: firstIcon, attribute: .right, multiplier: 1.0, constant: 8),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: firstInfoButton as Any, attribute: .top, relatedBy: .equal, toItem: firstIcon, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: firstInfoButton as Any, attribute: .right, relatedBy: .equal, toItem: proView, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: firstInfoButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: firstInfoButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: firstSeperator as Any, attribute: .top, relatedBy: .equal, toItem: firstIcon, attribute: .bottom, multiplier: 1.0, constant: 14),
            NSLayoutConstraint(item: firstSeperator as Any, attribute: .right, relatedBy: .equal, toItem: proView, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: firstSeperator as Any, attribute: .left, relatedBy: .equal, toItem: proView, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: firstSeperator as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: secondIcon as Any, attribute: .top, relatedBy: .equal, toItem: firstSeperator, attribute: .bottom, multiplier: 1.0, constant: 13),
            NSLayoutConstraint(item: secondIcon as Any, attribute: .left, relatedBy: .equal, toItem: proLabel, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: secondIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: secondIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: secondLabel as Any, attribute: .top, relatedBy: .equal, toItem: secondIcon, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: secondLabel as Any, attribute: .left, relatedBy: .equal, toItem: secondIcon, attribute: .right, multiplier: 1.0, constant: 8),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: secondInfoButton as Any, attribute: .top, relatedBy: .equal, toItem: secondIcon, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: secondInfoButton as Any, attribute: .right, relatedBy: .equal, toItem: proView, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: secondInfoButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: secondInfoButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: secondSeperator as Any, attribute: .top, relatedBy: .equal, toItem: secondIcon, attribute: .bottom, multiplier: 1.0, constant: 14),
            NSLayoutConstraint(item: secondSeperator as Any, attribute: .right, relatedBy: .equal, toItem: proView, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: secondSeperator as Any, attribute: .left, relatedBy: .equal, toItem: proView, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: secondSeperator as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: thirdIcon as Any, attribute: .top, relatedBy: .equal, toItem: secondSeperator, attribute: .bottom, multiplier: 1.0, constant: 13),
            NSLayoutConstraint(item: thirdIcon as Any, attribute: .left, relatedBy: .equal, toItem: proLabel, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: thirdIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: thirdIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: thirdLabel as Any, attribute: .top, relatedBy: .equal, toItem: thirdIcon, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: thirdLabel as Any, attribute: .left, relatedBy: .equal, toItem: thirdIcon, attribute: .right, multiplier: 1.0, constant: 8),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: thirdInfoButton as Any, attribute: .top, relatedBy: .equal, toItem: thirdIcon, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: thirdInfoButton as Any, attribute: .right, relatedBy: .equal, toItem: proView, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: thirdInfoButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: thirdInfoButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: thirdSeperator as Any, attribute: .top, relatedBy: .equal, toItem: thirdIcon, attribute: .bottom, multiplier: 1.0, constant: 14),
            NSLayoutConstraint(item: thirdSeperator as Any, attribute: .right, relatedBy: .equal, toItem: proView, attribute: .right, multiplier: 1.0, constant: -24),
            NSLayoutConstraint(item: thirdSeperator as Any, attribute: .left, relatedBy: .equal, toItem: proView, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: thirdSeperator as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: iapDescriptionLabel as Any, attribute: .top, relatedBy: .equal, toItem: thirdSeperator, attribute: .bottom, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: iapDescriptionLabel as Any, attribute: .left, relatedBy: .equal, toItem: proView, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: iapDescriptionLabel as Any, attribute: .right, relatedBy: .equal, toItem: proView, attribute: .right, multiplier: 1.0, constant: -24),
        ])

        view.addConstraints([
            NSLayoutConstraint(item: legalTextView as Any, attribute: .top, relatedBy: .equal, toItem: iapDescriptionLabel, attribute: .bottom, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: legalTextView as Any, attribute: .left, relatedBy: .equal, toItem: iapDescriptionLabel, attribute: .left, multiplier: 1.0, constant: -6),
        ])

        if Assembler.resolve(SessionManagerV2.self).session?.emailStatus == true {
            if UIDevice.current.isIphone5orLess() {
                view.addConstraints([
                    NSLayoutConstraint(item: continuePayButton as Any, attribute: .top, relatedBy: .equal, toItem: restoreButton, attribute: .bottom, multiplier: 1.0, constant: 24),
                ])
            } else {
                view.addConstraints([
                    NSLayoutConstraint(item: continuePayButton as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -24),
                ])
            }
            continueFreeButton.isHidden = true
        } else {
            if UIDevice.current.isIphone5orLess() {
                view.addConstraints([
                    NSLayoutConstraint(item: continuePayButton as Any, attribute: .top, relatedBy: .equal, toItem: restoreButton, attribute: .bottom, multiplier: 1.0, constant: 24),
                    NSLayoutConstraint(item: continueFreeButton as Any, attribute: .top, relatedBy: .equal, toItem: continuePayButton, attribute: .bottom, multiplier: 1.0, constant: 24),
                ])
            } else {
                view.addConstraints([
                    NSLayoutConstraint(item: continuePayButton as Any, attribute: .bottom, relatedBy: .equal, toItem: continueFreeButton, attribute: .top, multiplier: 1.0, constant: -24),
                    NSLayoutConstraint(item: continueFreeButton as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -34),
                ])
            }
            view.addConstraints([
                NSLayoutConstraint(item: continueFreeButton as Any, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            ])
        }
        view.addConstraints([
            NSLayoutConstraint(item: continuePayButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 48),
            NSLayoutConstraint(item: continuePayButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: continuePayButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -24),
        ])
        view.addConstraints([
            NSLayoutConstraint(item: restoreButton as Any, attribute: .top, relatedBy: .equal, toItem: proView, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: restoreButton as Any, attribute: .centerX, relatedBy: .equal, toItem: continuePayButton, attribute: .centerX, multiplier: 1.0, constant: 0),
        ])
    }

    @objc func makeFirstPlanSelected() {
        if windscribePlans.count > 0 {
            if let plan = windscribePlans.first(where: { $0.extId == firstPlanExt }) {
                setSelectedPlan(plan: plan)
            }
            let attributedTitle = NSMutableAttributedString(string: "\(TextsAsset.continue) \(firstPlanOptionButton.titleLabel?.text ?? "")")
            attributedTitle.addAttribute(.font, value: UIFont.bold(size: 16), range: NSRange(location: 0, length: TextsAsset.continue.count))
            continuePayButton.setAttributedTitle(attributedTitle, for: .normal)

            firstPlanOptionButton.setTitleColor(UIColor.seaGreen, for: .normal)
            firstPlanRadioButton.setImage(UIImage(named: ImagesAsset.radioPriceSelected), for: .normal)

            secondPlanOptionButton.setTitleColor(UIColor.whiteWithOpacity(opacity: 0.55), for: .normal)
            secondPlanRadioButtton.setImage(UIImage(named: ImagesAsset.radioPriceNotSelected), for: .normal)
        }
    }

    @objc func makeSecondPlanSelected() {
        if windscribePlans.count > 1 {
            if let plan = windscribePlans.first(where: { $0.extId == secondPlanExt }) {
                setSelectedPlan(plan: plan)
            }
            var priceToShow = ""
            if promoCode == nil {
                priceToShow = secondPlanOptionButton.titleLabel?.text ?? ""
            } else {
                priceToShow = discountLabel.text ?? ""
            }
            let attributedTitle = NSMutableAttributedString(string: "\(TextsAsset.continue) \(priceToShow)")
            attributedTitle.addAttribute(.font,
                                         value: UIFont.bold(size: 16),
                                         range: NSRange(location: 0, length: TextsAsset.continue.count))
            continuePayButton.setAttributedTitle(attributedTitle, for: .normal)

            secondPlanOptionButton.setTitleColor(UIColor.seaGreen, for: .normal)
            secondPlanRadioButtton.setImage(UIImage(named: ImagesAsset.radioPriceSelected), for: .normal)

            firstPlanOptionButton.setTitleColor(UIColor.whiteWithOpacity(opacity: 0.55), for: .normal)
            firstPlanRadioButton.setImage(UIImage(named: ImagesAsset.radioPriceNotSelected), for: .normal)
        }
    }
}

//
//  UpgradeViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-27.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import ExpyTableView
import StoreKit
import Swinject
import RxSwift

class UpgradeViewController: WSNavigationViewController {

    // MARK: - UI Elements
    var scrollView: UIScrollView!
    var contentView: UIView!
    var proView: UIView!
    var proLabel, pricingLabel, benefistsLabel: UILabel!
    var promoView: UIView!
    var promoLabel: UILabel!
    var promoIconImageView: UIImageView!
    var discountView: UIView!
    var discountLabel: UILabel!
    var discountPercentLabel: UILabel!
    var discountSeparateView: UIView!
    var pricesStackView: UIStackView!
    var pricesView: UIView!
    var firstPlanRadioButton,
        firstPlanOptionButton,
        secondPlanRadioButtton,
        secondPlanOptionButton: UIButton!
    var firstIcon,
        secondIcon,
        thirdIcon: UIImageView!
    var firstLabel,
        secondLabel,
        thirdLabel: UILabel!
    var firstInfoButton,
        secondInfoButton,
        thirdInfoButton: UIButton!
    var firstSeperator,
        secondSeperator,
        thirdSeperator: UIView!
    var firstIndicator,
        secondIndicator: UIActivityIndicatorView!
    var iapDescriptionLabel: UILabel!
    var legalTextView: UITextView!
    var continuePayButton,
        continueFreeButton,
        restoreButton: UIButton!
    // MARK: - Properties
    var viewModel: UpgradeViewModel!, logger: FileLogger!, router: UpgradeRouter!, alertManager: AlertManagerV2!
    var promoCode: String?
    var pcpID: String?
    var windscribePlans: [WindscribeInAppProduct] = []
    // MARK: - View controller callbacks
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Upgrade View")
        addViews()
        addAutoLayoutConstraints()
        bindState()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        addAutoLayoutConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        promoView.roundCorners(corners: [.bottomLeft], radius: 16)
    }
    // MARK: - Bind State
    private func bindState() {
        titleLabel.text = TextsAsset.UpgradeView.title
        viewModel.loadPlans(promo: promoCode)
        viewModel.plans.bind(onNext: { updatedPlans in
            DispatchQueue.main.async {
                if let plans = updatedPlans {
                    switch plans {
                    case .discounted(let plan):
                        self.renderDiscountViews(plan: plan)
                    case .standardPlans(let plans):
                        self.windscribePlans = plans
                        self.renderStandardPlans(windscribeProducts: plans)
                    }
                }
            }
        }).disposed(by: disposeBag)
        viewModel.purchaseState.bind(onNext: { purchaseState in
            DispatchQueue.main.async {
                if let purchaseState = purchaseState {
                    self.readyToMakePurchase(state: purchaseState)
                }
            }
        }).disposed(by: disposeBag)
        viewModel.upgradeState.bind(onNext: { state in
            DispatchQueue.main.async {
                switch state {
                case .success(let ghostAccount):
                    self.endLoading()
                    if ghostAccount {
                        self.router.goToSignUp(viewController: self, claimGhostAccount: true)
                    } else {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                case .loading:
                    self.showLoading()
                case .error(let error):
                    self.endLoading()
                    self.alertManager.showSimpleAlert(viewController: self, title: "", message: error, buttonText: TextsAsset.okay)
                case .none:
                    self.endLoading()
                }
            }
        }).disposed(by: disposeBag)
        viewModel.showProgress.bind(onNext: { show in
            DispatchQueue.main.async {
                if show {
                    self.showLoading()
                } else {
                    self.endLoading()
                }
            }
        }).disposed(by: disposeBag)
        viewModel.upgradeRouteState.bind(onNext: { routeID in
            if let routeID = routeID {
                self.router.routeTo(to: routeID, from: self)
            }
        }).disposed(by: disposeBag)
        viewModel.showFreeDataOption.bind(onNext: { show in
            DispatchQueue.main.async {
                self.continueFreeButton.isHidden = !show
            }
        }).disposed(by: disposeBag)
        viewModel.isDarkMode.bind(onNext: {
            self.updateTheme(isDarkMode: $0)
        }).disposed(by: disposeBag)
    }
    // MARK: - UI events
    @objc func continuePayButtonTapped() {
        viewModel.continuePayButtonTapped()
    }

    @objc func continueFreeButtonTapped() {
        viewModel.continueFreeButtonTapped()
    }

    @objc func restoreButtonTapped() {
        viewModel.restoreButtonTapped()
    }

    func setSelectedPlan(plan: WindscribeInAppProduct) {
        viewModel.setSelectedPlan(plan: plan)
    }

    @objc func infoButtonTapped(sender: UIButton) {
        var message = ""
        switch sender {
        case firstInfoButton:
            message = TextsAsset.UpgradeView.unlimitedDataMessage
        case secondInfoButton:
            message = TextsAsset.UpgradeView.allLocationsMessage
        case thirdInfoButton:
            message = TextsAsset.UpgradeView.robertMessage
        default:
            return
        }
        alertManager.showSimpleAlert(viewController: self, title: "", message: message, buttonText: TextsAsset.okay)
    }
    // MARK: - Helper
    private func renderPriceViews() {
        if promoCode == nil {
            promoView.isHidden = true
            discountView.isHidden = true
            promoIconImageView.isHidden = true
            pricesView.isHidden = false
        } else {
            promoView.isHidden = false
            discountView.isHidden = false
            promoIconImageView.isHidden = false
            pricesView.isHidden = true
        }
        view.layoutIfNeeded()
    }

    private func updateTheme(isDarkMode: Bool) {
        setupViews(isDark: isDarkMode)
        proView.backgroundColor = ThemeUtils.wrapperColor(isDarkMode: isDarkMode)

        proLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        pricingLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        benefistsLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        firstLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        secondLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        thirdLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        iapDescriptionLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)

        legalTextView.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)

        firstSeperator.backgroundColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        secondSeperator.backgroundColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        thirdSeperator.backgroundColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)

        discountSeparateView.backgroundColor = ThemeUtils.wrapperColor(isDarkMode: isDarkMode)

        firstPlanOptionButton.setTitleColor(ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode), for: .normal)

        legalTextView.linkTextAttributes = [ .foregroundColor: UIColor.white, .underlineColor: UIColor.clear]

        firstInfoButton.imageView?.setImageColor(color: ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode))
        secondInfoButton.imageView?.setImageColor(color: ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode))
        thirdInfoButton.imageView?.setImageColor(color: ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode))

        legalTextView.linkTextAttributes = [ .foregroundColor: ThemeUtils.primaryTextColor(isDarkMode: isDarkMode), .underlineColor: UIColor.clear]
    }

    private func readyToMakePurchase(state: PurchaseState) {
        firstPlanOptionButton.setTitle("\(state.price2)/ \(TextsAsset.UpgradeView.year)",
                                       for: .normal)
        secondPlanOptionButton.setTitle("\(state.price1)/ \(TextsAsset.UpgradeView.month)",
                                        for: .normal)
        continuePayButton.isEnabled = true
        renderPriceViews()
        makeFirstPlanSelected()
    }

    private func renderDiscountViews(plan: MobilePlan) {
        var durationLabel = TextsAsset.UpgradeView.months
        if plan.duration == 12 {
            durationLabel = TextsAsset.UpgradeView.year
        } else if plan.duration == 1 {
            durationLabel = TextsAsset.UpgradeView.month
        }
        discountLabel.text = "\(plan.price)/ \(durationLabel)"
        discountPercentLabel.text = "Save \(plan.discount)%"
        promoLabel.text = "\(plan.name)"
        makeFirstPlanSelected()
    }

    private func renderStandardPlans(windscribeProducts: [WindscribeInAppProduct]) {
        if windscribeProducts.count >= 2 {
            self.firstPlanOptionButton.setTitle(windscribeProducts[0].planLabel,
                                                for: .normal)
            self.secondPlanOptionButton.setTitle(windscribeProducts[1].planLabel,
                                                 for: .normal)
            self.continuePayButton.isEnabled = true
            self.makeFirstPlanSelected()
        }
        self.continuePayButton.isEnabled = true
        self.renderPriceViews()
        self.endLoading()
    }
}

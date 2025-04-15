//
//  PlanUpgradeViewController.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-01-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import RxSwift
import StoreKit
import Swinject
import UIKit
import SnapKit
import SwiftUI

class PlanUpgradeViewController: WSUIViewController {

    // MARK: UI Components

    let mainContentScrollView = UIScrollView()
    let backgroundView = UIView()
    var containerStarBackground = UIImageView()
    let mainStackView = UIStackView()
    var logoView: PlanUpgradeLogoView?
    let benefitsStackView = UIStackView()
    let subscribeButton = PlanUpgradeGradientButton()
    let legalTextContentView = UITextView()
    let legalTextContainerView = UIView()
    let subscriptionDetailsLabel = UILabel()
    var contentVerticalSpacing: CGFloat = 24
    var contentHorizontalSpacing: CGFloat = 16

    // Plan Selection
    let planSelectionStackView = UIStackView()
    lazy var planSelectionView = PlanUpgradeSelectionView()
    lazy var promoSelectionView = PlanUpgradePromoView()

    // Purchase Status
    private lazy var upgradeSuccessViewController = UpgradeSuccessViewController()

    // View Model
    var viewModel: PlanUpgradeViewModel?

    // Promo Properties
    var promoCode: String?
    var pcpID: String?
    var isPromotion = false

    // Subscription Plans
    var windscribePlans: [WindscribeInAppProduct] = []
    var firstPlanExtID: String?
    var secondPlanExtID: String?

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        isPromotion = promoCode != nil // Initial value while loading plans - will be updated

        createViews()
        setupUI()
        bindState()
        setupActionBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        changeNavigationBarStyle(isHidden: false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        updateViewSpacing()
    }

    override var traitCollection: UITraitCollection {
        let maxCategory: UIContentSizeCategory = .extraExtraLarge

        if super.traitCollection.preferredContentSizeCategory > maxCategory {
            return UITraitCollection(traitsFrom: [
                super.traitCollection,
                UITraitCollection(preferredContentSizeCategory: maxCategory)
            ])
        }

        return super.traitCollection
    }

    private func createViews() {
        guard let placeholderImage =  UIImage(named: ImagesAsset.Subscriptions.heroGraphic) else {
            return
        }

        logoView = PlanUpgradeLogoView(placeHolder: placeholderImage)
    }

    private func setupUI() {
        setTheme()
        doLayout()
    }

    private func isPlanPromotional() -> Bool {
        if let currentPlan = try? viewModel?.plans.value() {
            switch currentPlan {
            case .discounted:
                return true
            case .standardPlans, .unableToLoad:
                return false
            }
        }

        return false
    }

    // MARK: Bind State

    private func bindState() {
        guard let viewModel else { return }

        viewModel.loadPlans(promo: promoCode, id: pcpID)

        showLoading()

        viewModel.plans
            .bind(onNext: { [weak self] updatedPlans in
                guard let self, let viewModel = self.viewModel else { return }

                DispatchQueue.main.async {
                    if let plans = updatedPlans {
                        switch plans {
                        case .discounted(let applePlan, let appPlan):
                            self.windscribePlans = [applePlan]
                            self.isPromotion = self.isPlanPromotional()
                            self.doLayout()
                            self.renderPromoPlans(applePlan: applePlan, appPlan: appPlan)
                        case .standardPlans(let applePlans, let appPlans):
                            self.windscribePlans = applePlans
                            self.isPromotion = self.isPlanPromotional()
                            self.doLayout()
                            self.renderStandardPlans(applePlans: applePlans, appPlans: appPlans)
                        case .unableToLoad:
                            self.endLoading()
                            viewModel.showAlert(
                                title: "",
                                message: TextsAsset.UpgradeView.planBenefitUnableConnectAppStore)
                        }
                    }
                }
            })
            .disposed(by: disposeBag)

        viewModel.upgradeState
            .bind(onNext: { [weak self] state in
                    guard let self, let viewModel = self.viewModel else { return }

                    DispatchQueue.main.async {
                        switch state {
                        case let .success(ghostAccount):
                            self.endLoading()

                            // Registered Account should show positive response alert
                            viewModel.showAlert(title: TextsAsset.UpgradeView.planBenefitSuccessfullPurchaseTitle,
                                                message: TextsAsset.UpgradeView.planBenefitSuccessfullPurchase) { [weak self] in
                                guard let self else { return }

                                let navigationController = UINavigationController(
                                    rootViewController: upgradeSuccessViewController)

                                upgradeSuccessViewController.successScreenDismissed
                                    .observe(on: MainScheduler.instance)
                                    .subscribe(onNext: { [weak self] in
                                        guard let self else { return }

                                        if ghostAccount {
                                            self.navigationController?.dismiss(animated: true) {
                                                // Ghost Account should go sign up
                                                viewModel.navigateToSignUp(from: self)
                                            }
                                        } else {
                                            self.navigationController?.presentingViewController?.dismiss(animated: true)
                                        }
                                    })
                                    .disposed(by: disposeBag)
                                navigationController.modalPresentationStyle = .fullScreen

                                present(navigationController, animated: true)
                            }
                        case .loading:
                            self.showLoading()
                        case let .error(error):
                            self.endLoading()
                            viewModel.showAlert(title: "", message: error)
                        case let .titledError(title, error):
                            self.endLoading()
                            viewModel.showAlert(title: title, message: error)
                        case .none:
                            self.endLoading()
                        }
                    }
            })
            .disposed(by: disposeBag)

        viewModel.upgradeRouteState
            .bind(onNext: { [weak self] routeID in
                guard let self = self, let routeID = routeID else { return }

                self.viewModel?.routeTo(to: routeID, from: self)
            })
            .disposed(by: disposeBag)

        viewModel.showProgress
            .bind(onNext: { [weak self] show in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if show {
                        self.showLoading()
                    } else {
                        self.endLoading()
                    }
                }
            })
            .disposed(by: disposeBag)

        planSelectionView.selectedPlan
            .compactMap { $0 }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] planExtID in
                self?.selectDesiredPlan(planExtID: planExtID)
            })
            .disposed(by: disposeBag)
    }

    private func setupActionBindings() {
        subscribeButton.rx.tap
            .bind { [weak self] in
                self?.viewModel?.continuePayButtonTapped()
            }
            .disposed(by: disposeBag)
    }

    // MARK: Actions & Action Bindings

    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func restoreButtonTapped() {
        viewModel?.restoreButtonTapped()
    }

    // MARK: Render Plan Details

    private func renderStandardPlans(applePlans: [WindscribeInAppProduct], appPlans: [MobilePlan]) {
        // Standard Plans are monthly and yearly
        guard applePlans.count >= 2 else {
            endLoading()
            viewModel?.failedToLoadProducts()

            return
        }

        let firstPlan = applePlans.first { $0.extId == appPlans[0].extId }
        let secondPlan = applePlans.first { $0.extId == appPlans[1].extId }

        firstPlanExtID = appPlans[0].extId
        secondPlanExtID = appPlans[1].extId

        selectDesiredPlan(planExtID: firstPlanExtID)

        if let monthlyPlan = firstPlan, let yearlyPlan = secondPlan {
            planSelectionView.populateSelectionTypes(monthlyTier: monthlyPlan, yearlyTier: yearlyPlan)
        }

        subscribeButton.isEnabled = true
        endLoading()
    }

    private func renderPromoPlans(applePlan: WindscribeInAppProduct, appPlan: MobilePlan) {
        firstPlanExtID = appPlan.extId
        selectDesiredPlan(planExtID: firstPlanExtID)

        promoSelectionView.populateSelectionTypes(discountedTier: applePlan)

        subscribeButton.isEnabled = true
        endLoading()
    }

    func selectDesiredPlan(planExtID: String?) {
        if let plan = windscribePlans.first(where: { $0.extId == planExtID }) {
            viewModel?.setSelectedPlan(plan: plan)
        }
    }
}

struct PlanUpgradeViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let planUpgradeController = Assembler.resolve(PlanUpgradeViewController.self)

        let navigationController = UINavigationController(rootViewController: planUpgradeController).then {
            $0.modalPresentationStyle = .fullScreen
        }

        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // no-op
    }
}

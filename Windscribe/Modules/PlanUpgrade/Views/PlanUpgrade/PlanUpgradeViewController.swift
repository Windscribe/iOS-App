//
//  PlanUpgradeViewController.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-01-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

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
        setTransparentNavigationBar()
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

    private func setTransparentNavigationBar() {
        guard let navBar = navigationController?.navigationBar else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear

        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.isTranslucent = true
        navBar.backgroundColor = .clear

        view.backgroundColor = .clear
        navigationController?.view.backgroundColor = .clear
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
        if let currentPlan = viewModel?.plans.value {
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedPlans in
                guard let self, let viewModel = self.viewModel else { return }
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
            .store(in: &cancellables)

        viewModel.upgradeState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, let viewModel = self.viewModel else { return }
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
                            .receive(on: DispatchQueue.main)
                            .sink { [weak self] in
                                guard let self else { return }

                                if ghostAccount {
                                    self.navigationController?.dismiss(animated: true) {
                                        // Ghost Account should go sign up
                                        viewModel.navigateToSignUp(from: self)
                                    }
                                } else {
                                    self.navigationController?.presentingViewController?.dismiss(animated: true)
                                }
                            }
                            .store(in: &cancellables)
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
            .store(in: &cancellables)

        viewModel.upgradeRouteState
            .sink { [weak self] routeID in
                guard let self = self, let routeID = routeID else { return }

                self.viewModel?.routeTo(to: routeID, from: self)
            }
            .store(in: &cancellables)

        viewModel.showProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                guard let self = self else { return }
                if show {
                    self.showLoading()
                } else {
                    self.endLoading()
                }
            }
            .store(in: &cancellables)

        planSelectionView.selectedPlan
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] planExtID in
                self?.selectDesiredPlan(planExtID: planExtID)
            }
            .store(in: &cancellables)
    }

    private func setupActionBindings() {
        subscribeButton.publisher(for: .touchUpInside)
            .sink { [weak self] _ in
                self?.viewModel?.continuePayButtonTapped()
            }
            .store(in: &cancellables)
    }

    // MARK: Actions & Action Bindings

    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func restoreButtonTapped() {
        viewModel?.restoreButtonTapped()
    }

    // MARK: Render Plan Details

    private func renderStandardPlans(applePlans: [WindscribeInAppProduct], appPlans: [MobilePlanModel]) {
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

    private func renderPromoPlans(applePlan: WindscribeInAppProduct, appPlan: MobilePlanModel) {
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
    var promoCode: String?
    var pcpID: String?

    init(promoCode: String? = nil, pcpID: String? = nil) {
        self.promoCode = promoCode
        self.pcpID = pcpID
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let planUpgradeController = Assembler.resolve(PlanUpgradeViewController.self).then {
            $0.promoCode = promoCode
            $0.pcpID = pcpID
        }

        let navigationController = UINavigationController(rootViewController: planUpgradeController).then {
            $0.modalPresentationStyle = .fullScreen
        }

        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // no-op
    }
}

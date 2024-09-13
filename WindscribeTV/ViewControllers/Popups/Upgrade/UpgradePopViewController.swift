//
//  c.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 13/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class UpgradePopViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pricingLabel: UILabel!

    @IBOutlet weak var plansStackView: UIStackView!
    @IBOutlet weak var pricingStackView: UIStackView!

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var loadingView: UIView!

    let disposeBag = DisposeBag()
    var viewModel: UpgradeViewModel?
    var promoCode: String?
    var pcpID: String?

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bindViews()
    }

    // MARK: Setting up
    private func setup() {
        let infoList = [(title: TextsAsset.UpgradeView.unlimitedData, body: TextsAsset.UpgradeView.unlimitedDataMessage),
                        (title: TextsAsset.UpgradeView.allLocations, body: TextsAsset.UpgradeView.allLocationsMessage),
                        (title: TextsAsset.UpgradeView.robert, body: TextsAsset.UpgradeView.robertMessage)]
        infoList.forEach { (title: String, body: String) in
            let planView: UpgradePlanDetailView = UpgradePlanDetailView.fromNib()
            planView.setup(with: title, and: body)
            plansStackView.addArrangedSubview(planView)
        }
        plansStackView.addArrangedSubview(UIView())

        view.addBlueGradientBackground()
        titleLabel.text = TextsAsset.upgrade
        applyFonts()
    }

    private func applyFonts() {
        titleLabel.font = UIFont.bold(size: 72)
        titleLabel.textColor = .white
        pricingLabel.attributedText = NSAttributedString(string: TextsAsset.UpgradeView.pricing.uppercased(),
                                              attributes: [
                                                .font: UIFont.bold(size: 32),
                                                .foregroundColor: UIColor.white.withAlphaComponent(0.5),
                                                .kern: 4
                                              ])
    }

    private func bindViews() {
        guard let viewModel = viewModel else { return }
        viewModel.loadPlans(promo: promoCode)
        viewModel.plans.subscribe { plans in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                switch plans {
                case let .standardPlans(products, appPlans):
                    products.forEach {
                        let priceView: UpgradePricingView = UpgradePricingView.fromNib()
                        priceView.setup(with: $0.tvPlanLabel, and: $0.price, isSelected: $0.tvPlanLabel == products.first?.tvPlanLabel )
                        self.pricingStackView.addArrangedSubview(priceView)
                        priceView.delegate = self
                        priceView.plan = $0
                    }
                case let .discounted(plan, appPlan):
                    let priceView: UpgradePricingView = UpgradePricingView.fromNib()
                    priceView.setup(with: appPlan.name, and: plan.price)
                    self.pricingStackView.addArrangedSubview(priceView)
                    priceView.delegate = self
                default: return
                }
                self.pricingStackView.addArrangedSubview(UIView())
                self.pricingLabel.isHidden = false
                self.endLoading()
            }
        }.disposed(by: disposeBag)
        viewModel.upgradeState.bind(onNext: { state in
            DispatchQueue.main.async {
                switch state {
                case .success(let ghostAccount):
                    self.endLoading()
                    if ghostAccount {
                        // TODO: Go to signup view controller
                    } else {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                case .loading:
                    self.showLoading()
                case .error(let error):
                    self.endLoading()
                   // TODO: Show alert for error
                case .none:
                    self.endLoading()
                }
            }
        }).disposed(by: disposeBag)
    }

    private func endLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.loadingView.isHidden = !self.pricingLabel.isHidden
            self.containerView.isHidden = self.pricingLabel.isHidden
        }
    }

    private func showLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.loadingView.isHidden = false
            self.containerView.isHidden = true
        }
    }
}

extension UpgradePopViewController: UpgradePricingViewDelegate {
    func pricingOptionWasSelected(plan: WindscribeInAppProduct?) {
        if let plan = plan {
            viewModel?.setSelectedPlan(plan: plan)
            viewModel?.continuePayButtonTapped()
            return
        } else {
            viewModel?.continuePayButtonTapped()
        }
    }
}

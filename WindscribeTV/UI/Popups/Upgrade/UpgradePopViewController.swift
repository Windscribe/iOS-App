//
//  UpgradePopViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 13/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class UpgradePopViewController: UIViewController {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var pricingLabel: UILabel!

    @IBOutlet var plansStackView: UIStackView!
    @IBOutlet var pricingStackView: UIStackView!

    @IBOutlet var containerView: UIView!
    @IBOutlet var loadingView: UIView!

    let disposeBag = DisposeBag()
    var viewModel: UpgradeViewModel?
    var logger: FileLogger!
    var promoCode: String?
    var pcpID: String?

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Upgrade View")
        setup()
        bindViews()
    }

    // MARK: Setting up

    private func setup() {
        let infoList = [(title: TextsAsset.UpgradeView.unlimitedData, body: TextsAsset.UpgradeView.unlimitedDataMessage),
                        (title: TextsAsset.UpgradeView.allLocations, body: TextsAsset.UpgradeView.allLocationsMessage),
                        (title: TextsAsset.UpgradeView.robert, body: TextsAsset.UpgradeView.robertMessage)]
        for (title, body) in infoList {
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
        viewModel.loadPlans(promo: promoCode, id: pcpID)
        viewModel.plans.subscribe { plans in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                switch plans {
                case let .standardPlans(products, _):
                    for product in products {
                        let priceView: UpgradePricingView = UpgradePricingView.fromNib()
                        priceView.setup(with: product.tvPlanLabel, and: product.price, isSelected: product.tvPlanLabel == products.first?.tvPlanLabel)
                        self.pricingStackView.addArrangedSubview(priceView)
                        priceView.delegate = self
                        priceView.plan = product
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
                case let .success(ghostAccount):
                    self.endLoading()
                    if ghostAccount == true {
                        let vc = Assembler.resolve(SignUpViewController.self)
                        if self.navigationController == nil {
                            self.present(vc, animated: true)
                        } else {
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    } else {
                        if self.navigationController == nil {
                            self.dismiss(animated: true)
                        } else {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                case .loading:
                    self.showLoading()
                case let .error(error):
                    self.endLoading()
                    AlertManager.shared.showSimpleAlert(viewController: self, title: TextsAsset.error, message: error.description, buttonText: TextsAsset.okay)
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
            logger.logD(self, "Pricing Option Was Selected with plan \(plan)")
            viewModel?.continuePayButtonTapped()
            return
        } else {
            logger.logD(self, "Pricing Option Was Selected")
            viewModel?.continuePayButtonTapped()
        }
    }
}

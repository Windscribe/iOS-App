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

    var proLabel,
        pricingLabel,
        benefistsLabel: UILabel!

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

    var loadingAlert: UIAlertController?

    lazy var inAppPurchaseManager = Assembler.resolve(InAppPurchaseManager.self)
    var selectedPlan: WindscribeInAppProduct?
    var plans = [WindscribeInAppProduct]()
    var viewModel: UpgradeViewModel!, logger: FileLogger!, router: UpgradeRouter!, popupRouter: PopupRouter!
    let disposeBag = DisposeBag()
    var promoCode: String?
    var pcpID: String?
    var discountedPlan: MobilePlan?

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Upgrade View")

        titleLabel.text = TextsAsset.UpgradeView.title
        addViews()
        addAutoLayoutConstraints()

        (inAppPurchaseManager as? InAppPurchaseManagerImpl)?.delegate = self
        showLoading()
        if promoCode != nil && !promoCode!.isEmpty {
            loadPromoPlans()
        } else if PushNotificationManager.shared.lastNotificationPayload?.type == "promo" {
            // if an existing promo is avaialble always load promos first.
            promoCode = PushNotificationManager.shared.lastNotificationPayload?.promoCode
            pcpID = PushNotificationManager.shared.lastNotificationPayload?.pcpid
            loadPromoPlans()
        } else {
            promoCode = nil
            loadPlans()
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        addAutoLayoutConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        promoView.roundCorners(corners: [.bottomLeft], radius: 16)
    }

    func makePurchase(windscribeInAppProduct: WindscribeInAppProduct) {
        loadingAlert = viewModel.alertManager.getLoadingAlert()
        if loadingAlert != nil {
            present(loadingAlert!, animated: true) {
                self.inAppPurchaseManager.purchase(windscribeInAppProduct: windscribeInAppProduct)
            }
        }
    }

    func loadPlansFromDisk() {
        guard let mobilePlans = viewModel.localDatabase.getMobilePlans() else {
            self.endLoading()
            return
        }
        inAppPurchaseManager.fetchAvailableProducts(productIDs: mobilePlans.map({ $0.extId }))
    }

    func loadPlans() {
        viewModel.apiManager.getMobileBillingPlans().subscribe(onSuccess: { _ in
            self.loadPlansFromDisk()

        }, onFailure: {[weak self] _ in
            self?.endLoading()
            return
        }).disposed(by: disposeBag)

    }

    func loadPromoPlans() {

        // Replace this with wsnet api call
        NetworkManager.shared.getPromoMobilePlans(promoCode: promoCode ?? "",
                                                  success: { [weak self] plans in
            guard plans.mobilePlans.isEmpty == false else {
                if let self = self {
                    self.endLoading()
                    self.popupRouter.routeTo(to: .errorPopup(message: TextsAsset.UpgradeView.promoNotValid,
                                                             dismissAction: {
                        self.navigationController?.popViewController(animated: true)
                    }), from: self)
                }
                return
            }
            // if promo is not valid server may send regular plans
            if plans.mobilePlans.count >= 2 {
                self?.promoCode = nil
                self?.inAppPurchaseManager.fetchAvailableProducts(productIDs: plans.mobilePlans.map({ $0.extId }))
            } else {
                // Use first plan as discounted plan.
                self?.discountedPlan = plans.mobilePlans.first
                self?.inAppPurchaseManager.fetchAvailableProducts(productIDs: [self?.discountedPlan?.extId ?? ""])
            }
        }, failure: { [weak self] _ in
            if let self = self {
                self.endLoading()
                self.popupRouter.routeTo(to: .errorPopup(message: TextsAsset.UpgradeView.networkError,
                                                         dismissAction: {
                    self.navigationController?.popViewController(animated: true)
                }), from: self)
            }
        })
    }

    func showSuccesView() {
        logger.logD(self, "Showing purchase successful view")
        viewModel.apiManager.getSession().subscribe(onSuccess: { session in
            if session.isUserGhost == false {
                self.router.dismissPopup(action: .dismiss, navigationVC: self.navigationController)
            } else {
                self.router.goToSignUp(viewController: self, claimGhostAccount: true)
            }
        }, onFailure: {_ in
        }).disposed(by: disposeBag)

    }

    @objc func continuePayButtonTapped() {
        logger.logE(self, "User tapped to make purchase.")
        if let selectedPlan = selectedPlan {
            makePurchase(windscribeInAppProduct: selectedPlan)
        }
    }

    @objc func continueFreeButtonTapped() {
        if viewModel.sessionManager.session?.hasUserAddedEmail == true && viewModel.sessionManager.session?.emailStatus == false {
            router?.routeTo(to: RouteID.confirmEmail(delegate: self), from: self)
        } else if viewModel.sessionManager.session?.hasUserAddedEmail == false && viewModel.sessionManager.session?.isUserGhost == false {
            router.routeTo(to: RouteID.enterEmail, from: self)
        } else {
            self.router.goToSignUp(viewController: self, claimGhostAccount: true)
        }
    }

    @objc func restoreButtonTapped() {
        logger.logD(self, "User tapped to restore purchases.")
        self.showLoading()
        inAppPurchaseManager.restorePurchase()
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
        viewModel.alertManager.showSimpleAlert(viewController: self, title: "", message: message, buttonText: TextsAsset.okay)
    }

}

// MARK: - Extensions
extension UpgradeViewController: InAppPurchaseManagerDelegate {

    func purchasedSuccessfully(transaction: SKPaymentTransaction, appleID: String, appleData: String,  appleSIG: String) {
        // Replace this with wsnet api call

        NetworkManager.shared.sendPurchase(appleID: appleID, appleData: appleData, appleSIG: appleSIG) { apiResult in
            switch apiResult {
            case .ApiError(let error):
                DispatchQueue.main.async {
                    self.loadingAlert?.dismiss(animated: true, completion: nil)
                    LogManager.shared.log(text: "\(error)")
                    self.saveIncompleteTransactionDetails(appleID: appleID, appleData: appleData, appleSIG: appleSIG)
                    self.popupRouter.routeTo(to: .errorPopup(message: "\(error)", dismissAction: { }), from: self)
                }
            case .Success:
                LogManager.shared.log(
                    activity: String(describing: UpgradeViewController.self),
                    text: "Sending Apple purchase data successful.",
                    type: .error
                )
                self.postpcpID()
                // remove transaction values from user defaults
                self.saveIncompleteTransactionDetails(appleID: nil, appleData: nil, appleSIG: nil)
            }
        }
    }

    func postpcpID() {
        if let payID = pcpID {
            viewModel.apiManager.postBillingCpID(pcpID: payID).subscribe(onSuccess: { _ in
                DispatchQueue.main.async { [weak self] in
                    self?.loadingAlert?.dismiss(animated: true, completion: nil)
                    self?.showSuccesView()
                }
            }, onFailure: { _ in }).disposed(by: disposeBag)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.loadingAlert?.dismiss(animated: true, completion: nil)
                self?.showSuccesView()
            }
        }
    }

    func didFetchAvailableProducts(windscribeProducts: [WindscribeInAppProduct]) {
        DispatchQueue.main.async {
            self.plans = windscribeProducts
            if self.promoCode != nil && self.discountedPlan != nil {
                if windscribeProducts.count > 0 {
                    self.renderDiscountViews(price: windscribeProducts[0].price)
                }
            } else {
                if windscribeProducts.count >= 2 {
                    self.firstPlanOptionButton.setTitle(windscribeProducts[0].planLabel,
                                                      for: .normal)
                    self.secondPlanOptionButton.setTitle(windscribeProducts[1].planLabel,
                                                       for: .normal)
                    self.continuePayButton.isEnabled = true
                    self.makeFirstPlanSelected()
                }
            }
            self.continuePayButton.isEnabled = true
            self.renderPriceViews()
            self.endLoading()
        }
    }

    private func renderDiscountViews(price: String) {
        guard promoCode != nil,
              let discountedPlan = discountedPlan else { return }

        var durationLabel = TextsAsset.UpgradeView.months
        if discountedPlan.duration == 12 {
            durationLabel = TextsAsset.UpgradeView.year
        } else if discountedPlan.duration == 1 {
            durationLabel = TextsAsset.UpgradeView.month
        }
        discountLabel.text = "\(price)/ \(durationLabel)"
        discountPercentLabel.text = "Save \(discountedPlan.discount)%"
        promoLabel.text = "\(discountedPlan.name)"
        makeFirstPlanSelected()
    }

    func readyToMakePurchase(price1: String, price2: String) {
        firstPlanOptionButton.setTitle("\(price2)/ \(TextsAsset.UpgradeView.year)",
                                    for: .normal)
        secondPlanOptionButton.setTitle("\(price1)/ \(TextsAsset.UpgradeView.month)",
                                     for: .normal)
        continuePayButton.isEnabled = true
        renderPriceViews()
        makeFirstPlanSelected()
    }

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

    func failedToPurchase() {
        logger.logE(self, "InApp purchase failed.")
        DispatchQueue.main.async { [weak self] in
            if self?.loadingAlert != nil {
                self?.loadingAlert?.dismiss(animated: true, completion: nil)
            }
        }
    }

    func unableToRestorePurchase(error: Error) {
        DispatchQueue.main.async {
            self.endLoading()
            if let err = error as? URLError, err.code  == URLError.Code.notConnectedToInternet {
                self.popupRouter.routeTo(to: .errorPopup(message: Errors.noNetwork.description, dismissAction: { }), from: self)
            } else if let _ = error as? URLError {
                self.popupRouter.routeTo(to: .errorPopup(message: Errors.unknownError.description, dismissAction: { }), from: self)
            } else {
                self.popupRouter.routeTo(to: .errorPopup(message: TextsAsset.PurchaseRestoredAlert.error, dismissAction: { }), from: self)
            }
        }
    }

    func setVerifiedTransaction(transaction: UncompletedTransactions?, error: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.endLoading()
            if transaction == nil {
                if let self = self {
                    self.logger.logD(self, "Restored failed with error: \(error ?? "")")
                    self.popupRouter.routeTo(to: .errorPopup(message: TextsAsset.PurchaseRestoredAlert.error, dismissAction: { }), from: self)
                }
            } else {
                self?.logger.logD(self, "Successfully verified item: \(transaction?.description ?? "")")
                self?.showSuccesView()
            }
        }
    }

    func failedToLoadProducts() {
        self.endLoading()
    }

    func unableToMakePurchase() {
        self.loadingAlert?.dismiss(animated: true, completion: nil)
    }

    func saveIncompleteTransactionDetails(appleID: String?, appleData: String?,  appleSIG: String?) {
        viewModel.saveAppleData(appleID: appleID, appleData: appleData, appleSig: appleSIG)
    }
}

extension UpgradeViewController: ConfirmEmailViewControllerDelegate {

    func dismissWith(action: ConfirmEmailAction) {
        // router?.dismissPopup(action: action, navigationVC: self.navigationController)
    }

}

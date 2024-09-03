//
//  UpgradeViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-03.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import StoreKit

enum UpgradeState {
    case success(Bool)
    case loading
    case error(String)
}

enum Plans {
    case discounted(MobilePlan)
    case standardPlans([WindscribeInAppProduct])
}

enum RestoreState {
    case error(String)
    case success
}

struct PurchaseState {
    var price1: String
    var price2: String
}

protocol UpgradeViewModel {
    var upgradeState: BehaviorSubject<UpgradeState?> { get }
    var plans: BehaviorSubject<Plans?> { get }
    var upgradeRouteState: BehaviorSubject<RouteID?> { get }
    var purchaseState: BehaviorSubject<PurchaseState?> { get }
    var restoreState: BehaviorSubject<RestoreState?> { get }
    var showProgress: BehaviorSubject<Bool> { get }
    var showFreeDataOption: BehaviorSubject<Bool> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }

    func loadPlans(promo: String?)
    func continuePayButtonTapped()
    func continueFreeButtonTapped()
    func restoreButtonTapped()
    func setSelectedPlan(plan: WindscribeInAppProduct)
}

class UpgradeViewModelImpl: UpgradeViewModel, InAppPurchaseManagerDelegate, ConfirmEmailViewControllerDelegate {

    let alertManager: AlertManagerV2
    let localDatabase: LocalDatabase
    let apiManager: APIManager
    let sessionManager: SessionManagerV2
    let preferences: Preferences
    var inAppPurchaseManager: InAppPurchaseManager
    let pushNotificationManager: PushNotificationManagerV2
    let billingRepository: BillingRepository
    let logger: FileLogger

    let upgradeState: BehaviorSubject<UpgradeState?> = BehaviorSubject(value: nil)
    let showProgress: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    var plans: BehaviorSubject<Plans?> = BehaviorSubject(value: nil)
    var upgradeRouteState: BehaviorSubject<RouteID?> = BehaviorSubject(value: nil)
    var purchaseState: BehaviorSubject<PurchaseState?> = BehaviorSubject(value: nil)
    var restoreState: BehaviorSubject<RestoreState?> = BehaviorSubject(value: nil)
    var showFreeDataOption = BehaviorSubject(value: false)
    let isDarkMode: BehaviorSubject<Bool>

    var selectedPlan: WindscribeInAppProduct?
    let disposeBag = DisposeBag()
    var pcpID: String?
    var pushNotificationPayload: PushNotificationPayload?

    init(alertManager: AlertManagerV2, localDatabase: LocalDatabase, apiManager: APIManager, sessionManager: SessionManagerV2, preferences: Preferences, inAppManager: InAppPurchaseManager, pushNotificationManager: PushNotificationManagerV2, billingRepository: BillingRepository, logger: FileLogger, themeManager: ThemeManager) {
        self.alertManager = alertManager
        self.localDatabase = localDatabase
        self.apiManager = apiManager
        self.sessionManager = sessionManager
        self.preferences = preferences
        self.inAppPurchaseManager = inAppManager
        self.pushNotificationManager = pushNotificationManager
        self.billingRepository = billingRepository
        self.logger = logger
        isDarkMode = themeManager.darkTheme
        self.inAppPurchaseManager.delegate = self
        checkAccountStatus()
    }

    private func saveAppleData( appleID: String?, appleData: String?, appleSig: String?) {
        DispatchQueue.main.async {
            self.preferences.saveActiveAppleID(id: appleID)
            self.preferences.saveActiveAppleData(data: appleData)
            self.preferences.saveActiveAppleSig(sig: appleSig)
        }
    }

    private func checkAccountStatus() {
        if let session = sessionManager.session {
            showFreeDataOption.onNext(session.isUserGhost || !session.hasUserAddedEmail || (session.hasUserAddedEmail && session.userNeedsToConfirmEmail))
        }
    }

    func loadPlans(promo: String?) {
        var promoCode = promo
        if pushNotificationPayload?.type == "promo" {
            promoCode = pushNotificationPayload?.promoCode
            pcpID = pushNotificationPayload?.pcpid
        }
        logger.logD(self, "Loading billing plans.")
        showProgress.onNext(true)
        billingRepository.getMobilePlans(promo: promo).observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { mobilePlans in
                self.logger.logD(self, "Plans loaded successfully. Count: \(mobilePlans.count).")
                if promoCode == nil && mobilePlans.count >= 2 {
                    self.logger.logD(self, "Loading plan info from apple.")
                    self.logger.logD(self, mobilePlans.map({$0.extId}).joined())
                    self.inAppPurchaseManager.fetchAvailableProducts(productIDs: mobilePlans.map({$0.extId}))
                } else {
                    self.showProgress.onNext(false)
                    if let updatedPlan = mobilePlans.first {
                        self.logger.logD(self, "showing promo plans.")
                        self.plans.onNext(.discounted(updatedPlan))
                    }
                }
            }, onFailure: { _ in
                self.showProgress.onNext(false)
            }).disposed(by: disposeBag)
    }

    func continuePayButtonTapped() {
        logger.logD(self, "User tapped to upgrade.")
        self.upgradeState.onNext(.loading)
        if let selectedPlan = selectedPlan {
            inAppPurchaseManager.purchase(windscribeInAppProduct: selectedPlan)
        }
    }

    func continueFreeButtonTapped() {
        logger.logD(self, "User tapped to get free data.")
        if sessionManager.session?.hasUserAddedEmail == true && sessionManager.session?.emailStatus == false {
            upgradeRouteState.onNext(RouteID.confirmEmail(delegate: self))
        } else if sessionManager.session?.hasUserAddedEmail == false && sessionManager.session?.isUserGhost == false {
            upgradeRouteState.onNext(RouteID.enterEmail)
        } else {
            upgradeRouteState.onNext(RouteID.signup(claimGhostAccount: true))
        }
    }

    func restoreButtonTapped() {
        logger.logD(self, "User tapped to restore purchases.")
        self.upgradeState.onNext(.loading)
        inAppPurchaseManager.restorePurchase()
    }

    func setSelectedPlan(plan: WindscribeInAppProduct) {
        logger.logD(self, "Selected plan: \(plan.planLabel)")
        selectedPlan = plan
    }

    func readyToMakePurchase(price1: String, price2: String) {
        logger.logD(self, "Ready to make purchase: Apple price1: \(price1) Apple price2: \(price2)")
        purchaseState.onNext(PurchaseState(price1: price1, price2: price2))
    }

    func didFetchAvailableProducts(windscribeProducts: [WindscribeInAppProduct]) {
        self.showProgress.onNext(false)
        plans.onNext(.standardPlans(windscribeProducts))
    }

    func purchasedSuccessfully(transaction: SKPaymentTransaction, appleID: String, appleData: String, appleSIG: String) {
        logger.logD(self, "Purchase successful.")
        apiManager.verifyApplePayment(appleID: appleID, appleData: appleData, appleSIG: appleSIG).subscribe(onSuccess: { _ in
            self.logger.logD(self, "Purchase verified successfully")
            self.saveAppleData(appleID: nil, appleData: nil, appleSig: nil)
            self.postpcpID()
        }, onFailure: { error in
            self.logger.logE(self, "Failed to verify payment and saving for later. \(error)")
            self.saveAppleData(appleID: appleID, appleData: appleData, appleSig: appleSIG)
            if let error = error as? Errors {
                switch error {
                case .apiError(let error):
                    self.upgradeState.onNext(.error(error.errorMessage ?? ""))
                default:
                    self.upgradeState.onNext(.error(error.description))
                }
            }
        }).disposed(by: disposeBag)
    }

    private func upgrade() {
        apiManager.getSession().subscribe(onSuccess: { session in
            self.upgradeState.onNext(.success(session.isUserGhost))
        },onFailure: { _ in
            self.upgradeState.onNext(.success(false))
        }).disposed(by: disposeBag)
    }

    private func postpcpID() {
        if let payID = pcpID {
            self.logger.logD(self, "Posting pcpID")
            apiManager.postBillingCpID(pcpID: payID).observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { _ in
                self.upgrade()
            }, onFailure: { _ in
                self.logger.logE(self, "Failed to post pcpID")
                self.upgrade()
            }).disposed(by: disposeBag)
        } else {
            upgrade()
        }
    }

    private func listenPushNotificationPayload() {
        pushNotificationManager.notification.subscribe(onNext: { [weak self] payload in
            self?.pushNotificationPayload = payload
        }).disposed(by: disposeBag)
    }

    func failedToPurchase() {
        self.logger.logE(self, "Failed to complete transaction.")
        self.upgradeState.onNext(.error("Failed to complete transaction."))
    }

    func unableToMakePurchase() {
        self.logger.logE(self, "Failed to complete transaction.")
        self.upgradeState.onNext(.error("Failed to complete transaction."))
    }

    func setVerifiedTransaction(transaction: UncompletedTransactions?, error: String?) {
        DispatchQueue.main.async { [weak self] in
            if transaction == nil {
                self?.logger.logE(UpgradeViewModel.self, error ?? "Failed to restore transaction.")
                self?.upgradeState.onNext(.error(error ?? "Failed to restore transaction."))
            } else {
                self?.logger.logD(UpgradeViewModel.self, "Successfully verified item: \(transaction?.description ?? "")")
                self?.upgrade()
            }
        }
    }

    func failedToLoadProducts() {
        self.logger.logE(self, "Failed to load products. Check your network and try again.")
        self.showProgress.onNext(false)
        self.upgradeState.onNext(.error("Failed to load products. Check your network and try again."))
    }

    func unableToRestorePurchase(error: any Error) {
        self.logger.logE(self, "Unable to restore purchase. \(error)")
        if let err = error as? URLError, err.code  == URLError.Code.notConnectedToInternet {
            self.upgradeState.onNext(.error(Errors.noNetwork.description))
        } else if error as? URLError != nil {
            self.upgradeState.onNext(.error(Errors.unknownError.description))
        } else {
            self.upgradeState.onNext(.error(TextsAsset.PurchaseRestoredAlert.error))
        }
    }

    func dismissWith(action: ConfirmEmailAction) {}
}

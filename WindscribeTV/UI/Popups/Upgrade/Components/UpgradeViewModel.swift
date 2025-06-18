//
//  UpgradeViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/02/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
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
    case discounted(WindscribeInAppProduct, MobilePlan)
    case standardPlans([WindscribeInAppProduct], [MobilePlan])
    case unableToLoad
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
    var restoreState: BehaviorSubject<RestoreState?> { get }
    var showProgress: BehaviorSubject<Bool> { get }
    var showFreeDataOption: BehaviorSubject<Bool> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }

    func loadPlans(promo: String?, id: String?)
    func continuePayButtonTapped()
    func continueFreeButtonTapped()
    func restoreButtonTapped()
    func setSelectedPlan(plan: WindscribeInAppProduct)
}

class UpgradeViewModelImpl: UpgradeViewModel, InAppPurchaseManagerDelegate, ConfirmEmailViewControllerDelegate {
    let alertManager: AlertManagerV2
    let localDatabase: LocalDatabase
    let apiManager: APIManager
    let sessionManager: SessionManaging
    let preferences: Preferences
    var inAppPurchaseManager: InAppPurchaseManager
    let pushNotificationManager: PushNotificationManagerV2
    let billingRepository: BillingRepository
    let logger: FileLogger

    let upgradeState: BehaviorSubject<UpgradeState?> = BehaviorSubject(value: nil)
    let showProgress: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    var plans: BehaviorSubject<Plans?> = BehaviorSubject(value: nil)
    var upgradeRouteState: BehaviorSubject<RouteID?> = BehaviorSubject(value: nil)
    var restoreState: BehaviorSubject<RestoreState?> = BehaviorSubject(value: nil)
    var showFreeDataOption = BehaviorSubject(value: false)
    let isDarkMode: BehaviorSubject<Bool>

    var selectedPlan: WindscribeInAppProduct?
    let disposeBag = DisposeBag()
    var pcpID: String?
    var pushNotificationPayload: PushNotificationPayload?
    private var mobilePlans: [MobilePlan]?

    init(alertManager: AlertManagerV2, localDatabase: LocalDatabase, apiManager: APIManager, sessionManager: SessionManaging, preferences: Preferences, inAppManager: InAppPurchaseManager, pushNotificationManager: PushNotificationManagerV2, billingRepository: BillingRepository, logger: FileLogger, lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.alertManager = alertManager
        self.localDatabase = localDatabase
        self.apiManager = apiManager
        self.sessionManager = sessionManager
        self.preferences = preferences
        inAppPurchaseManager = inAppManager
        self.pushNotificationManager = pushNotificationManager
        self.billingRepository = billingRepository
        self.logger = logger
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        inAppPurchaseManager.delegate = self
        checkAccountStatus()
    }

    private func saveAppleData(appleID: String?, appleData: String?, appleSig: String?) {
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

    func loadPlans(promo: String?, id: String?) {
        var promoCode = promo
        pcpID = id
        if pushNotificationPayload?.type == "promo" {
            promoCode = pushNotificationPayload?.promoCode
            pcpID = pushNotificationPayload?.pcpid
        }
        logger.logD(self, "Loading billing plans. Promo: \(promoCode ?? "N/A")")
        showProgress.onNext(true)
        billingRepository.getMobilePlans(promo: promoCode)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] mobilePlans in
                guard let self = self else { return }
                for p in mobilePlans {
                    let discount = p.discount >= 0 ? "\(p.discount)%" : "N/A"
                    self.logger.logD(self, "Plan: \(p.name) Ext: \(p.extId) Duration: \(p.duration) Discount: \(discount)")
                }
                self.mobilePlans = mobilePlans
                self.showProgress.onNext(false)
                if mobilePlans.count > 0 {
                    self.inAppPurchaseManager.fetchAvailableProducts(productIDs: mobilePlans.map { $0.extId })
                }
            }, onFailure: { [weak self] _ in
                self?.showProgress.onNext(false)
            }).disposed(by: disposeBag)
    }

    func continuePayButtonTapped() {
        logger.logD(self, "User tapped to upgrade.")
        upgradeState.onNext(.loading)
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
        upgradeState.onNext(.loading)
        inAppPurchaseManager.restorePurchase()
    }

    func setSelectedPlan(plan: WindscribeInAppProduct) {
        logger.logD(self, "Selected plan: \(plan.planLabel)")
        selectedPlan = plan
    }

    func didFetchAvailableProducts(windscribeProducts: [WindscribeInAppProduct]) {
        DispatchQueue.main.async { [self] in
            showProgress.onNext(false)
            if let discountedWindscribePlan = mobilePlans?.first(where: { $0.discount >= 0}), let discountedApplePlan = windscribeProducts.first(where: {$0.extId == discountedWindscribePlan.extId}) {
                plans.onNext(.discounted(discountedApplePlan, discountedWindscribePlan))
            } else if windscribeProducts.count > 0 && windscribeProducts.count == mobilePlans?.count {
                plans.onNext(.standardPlans(windscribeProducts, mobilePlans ?? []))
            } else {
                plans.onNext(.unableToLoad)
            }
        }
    }

    func failedCanceledByUser() {
        logger.logE(self, "Failed to complete transaction. Purchase canceled by user.")
        // Upgrade state will not send an error here so dismiss screen will not show alert
        upgradeState.onNext(.none)
    }

    func failedDueToNetworkIssue() {
        logger.logE(self, "Failed to complete transaction. Problem with internet connection.")
        upgradeState.onNext(.error(TextsAsset.UpgradeView.planBenefitTransactionFailedAlertTitle))
    }

    func purchasedSuccessfully(transaction _: SKPaymentTransaction, appleID: String, appleData: String, appleSIG: String) {
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
                case let .apiError(error):
                    self.upgradeState.onNext(.error(error.errorMessage ?? ""))
                default:
                    self.upgradeState.onNext(.error(error.description))
                }
            }
        }).disposed(by: disposeBag)
    }

    private func upgrade() {
        self.logger.logI(self, "Getting new session.")
        apiManager.getSession(nil).observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { session in
            self.logger.logI(self, "Received updated session.")
            self.localDatabase.saveSession(session: session).disposed(by: self.disposeBag)
            self.upgradeState.onNext(.success(session.isUserGhost))
        }, onFailure: { _ in
            self.logger.logE(self, "Failure to update session.")
            self.upgradeState.onNext(.success(false))
        }).disposed(by: disposeBag)
    }

    private func postpcpID() {
        if let payID = pcpID {
            logger.logD(self, "Posting pcpID")
            apiManager.postBillingCpID(pcpID: payID).observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { _ in
                self.upgrade()
            }, onFailure: { _ in
                self.logger.logE(self, "Failed to post pcpID")
                self.upgrade()
            }).disposed(by: disposeBag)
        } else {
            logger.logE(self, "No pcpID now upgrading.")
            upgrade()
        }
    }

    private func listenPushNotificationPayload() {
        pushNotificationManager.notification.subscribe(onNext: { [weak self] payload in
            self?.pushNotificationPayload = payload
        }).disposed(by: disposeBag)
    }

    func failedToPurchase() {
        logger.logE(self, "Failed to complete transaction.")
        upgradeState.onNext(.error("Failed to complete transaction."))
    }

    func unableToMakePurchase() {
        logger.logE(self, "Failed to complete transaction.")
        upgradeState.onNext(.error("Failed to complete transaction."))
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
        logger.logE(self, "Failed to load products. Check your network and try again.")
        showProgress.onNext(false)
        upgradeState.onNext(.error("Failed to load products. Check your network and try again."))
    }

    func unableToRestorePurchase(error: any Error) {
        logger.logE(self, "Unable to restore purchase. \(error)")
        if let err = error as? URLError, err.code == URLError.Code.notConnectedToInternet {
            upgradeState.onNext(.error(Errors.noNetwork.description))
        } else if error as? URLError != nil {
            upgradeState.onNext(.error(Errors.unknownError.description))
        } else {
            upgradeState.onNext(.error(TextsAsset.PurchaseRestoredAlert.error))
        }
    }

    func dismissWith(action _: ConfirmEmailAction) {}
}

//
//  UpgradeViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/02/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine
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
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }

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
    let sessionManager: SessionManager
    let userSessionRepository: UserSessionRepository
    let preferences: Preferences
    var inAppPurchaseManager: InAppPurchaseManager
    let pushNotificationManager: PushNotificationManager
    let mobilePlanRepository: MobilePlanRepository
    let logger: FileLogger

    let upgradeState: BehaviorSubject<UpgradeState?> = BehaviorSubject(value: nil)
    let showProgress: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    var plans: BehaviorSubject<Plans?> = BehaviorSubject(value: nil)
    var upgradeRouteState: BehaviorSubject<RouteID?> = BehaviorSubject(value: nil)
    var restoreState: BehaviorSubject<RestoreState?> = BehaviorSubject(value: nil)
    var showFreeDataOption = BehaviorSubject(value: false)
    let isDarkMode: CurrentValueSubject<Bool, Never>

    var selectedPlan: WindscribeInAppProduct?
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    var pcpID: String?
    var pushNotificationPayload: PushNotificationPayload?
    private var mobilePlans: [MobilePlan]?

    init(alertManager: AlertManagerV2,
         localDatabase: LocalDatabase,
         apiManager: APIManager,
         sessionManager: SessionManager,
         userSessionRepository: UserSessionRepository,
         preferences: Preferences,
         inAppManager: InAppPurchaseManager,
         pushNotificationManager: PushNotificationManager,
         mobilePlanRepository: MobilePlanRepository,
         logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.alertManager = alertManager
        self.localDatabase = localDatabase
        self.apiManager = apiManager
        self.userSessionRepository = userSessionRepository
        self.sessionManager = sessionManager
        self.preferences = preferences
        inAppPurchaseManager = inAppManager
        self.pushNotificationManager = pushNotificationManager
        self.mobilePlanRepository = mobilePlanRepository
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
        if let session = userSessionRepository.sessionModel {
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
        logger.logD("UpgradeViewModelImpl", "Loading billing plans. Promo: \(promoCode ?? "N/A")")
        showProgress.onNext(true)
        Task { @MainActor in
            do {
                let mobilePlans = try await mobilePlanRepository.getMobilePlans(promo: promoCode)

                for p in mobilePlans {
                    let discount = p.discount >= 0 ? "\(p.discount)%" : "N/A"
                    logger.logD("UpgradeViewModelImpl", "Plan: \(p.name) Ext: \(p.extId) Duration: \(p.duration) Discount: \(discount)")
                }
                self.mobilePlans = mobilePlans
                showProgress.onNext(false)
                if mobilePlans.count > 0 {
                    inAppPurchaseManager.fetchAvailableProducts(productIDs: mobilePlans.map { $0.extId })
                }
            } catch {
                logger.logE("UpgradeViewModelImpl", "Failed to load mobile plans: \(error)")
                showProgress.onNext(false)
            }
        }
    }

    func continuePayButtonTapped() {
        logger.logD("UpgradeViewModelImpl", "User tapped to upgrade.")
        upgradeState.onNext(.loading)
        if let selectedPlan = selectedPlan {
            inAppPurchaseManager.purchase(windscribeInAppProduct: selectedPlan)
        }
    }

    func continueFreeButtonTapped() {
        logger.logD("UpgradeViewModelImpl", "User tapped to get free data.")
        if userSessionRepository.sessionModel?.hasUserAddedEmail == true && userSessionRepository.sessionModel?.emailStatus == false {
            upgradeRouteState.onNext(RouteID.confirmEmail(delegate: self))
        } else if userSessionRepository.sessionModel?.hasUserAddedEmail == false && userSessionRepository.sessionModel?.isUserGhost == false {
            upgradeRouteState.onNext(RouteID.enterEmail)
        } else {
            upgradeRouteState.onNext(RouteID.signup(claimGhostAccount: true))
        }
    }

    func restoreButtonTapped() {
        logger.logD("UpgradeViewModelImpl", "User tapped to restore purchases.")
        upgradeState.onNext(.loading)
        inAppPurchaseManager.restorePurchase()
    }

    func setSelectedPlan(plan: WindscribeInAppProduct) {
        logger.logD("UpgradeViewModelImpl", "Selected plan: \(plan.planLabel)")
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
        logger.logE("UpgradeViewModelImpl", "Failed to complete transaction. Purchase canceled by user.")
        // Upgrade state will not send an error here so dismiss screen will not show alert
        upgradeState.onNext(.none)
    }

    func failedDueToNetworkIssue() {
        logger.logE("UpgradeViewModelImpl", "Failed to complete transaction. Problem with internet connection.")
        upgradeState.onNext(.error(TextsAsset.UpgradeView.planBenefitTransactionFailedAlertTitle))
    }

    func purchasedSuccessfully(transaction _: SKPaymentTransaction, appleID: String, appleData: String, appleSIG: String) {
        logger.logD("UpgradeViewModelImpl", "Purchase successful.")
        Task { [weak self] in
            guard let self = self else { return }

            do {
                _ = try await self.apiManager.verifyApplePayment(appleID: appleID, appleData: appleData, appleSIG: appleSIG)
                await MainActor.run {
                    self.logger.logD("UpgradeViewModelImpl", "Purchase verified successfully")
                    self.saveAppleData(appleID: nil, appleData: nil, appleSig: nil)
                    self.postpcpID()
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("UpgradeViewModelImpl", "Failed to verify payment and saving for later. \(error)")
                    self.saveAppleData(appleID: appleID, appleData: appleData, appleSig: appleSIG)
                    if let error = error as? Errors {
                        switch error {
                        case let .apiError(error):
                            self.upgradeState.onNext(.error(error.errorMessage ?? ""))
                        default:
                            self.upgradeState.onNext(.error(error.description))
                        }
                    }
                }
            }
        }
    }

    private func upgrade() {
        self.logger.logI("UpgradeViewModelImpl", "Getting new session.")
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                try await sessionManager.updateSession()
                let session = userSessionRepository.sessionModel
                self.logger.logI("UpgradeViewModelImpl", "Received updated session.")
                self.upgradeState.onNext(.success(session?.isUserGhost ?? false))
            } catch {
                await MainActor.run {
                    self.logger.logE("UpgradeViewModelImpl", "Failure to update session.")
                    self.upgradeState.onNext(.success(false))
                }
            }
        }
    }

    private func postpcpID() {
        if let payID = pcpID {
            logger.logD("UpgradeViewModelImpl", "Posting pcpID")
            Task { [weak self] in
                guard let self = self else { return }

                do {
                    _ = try await self.apiManager.postBillingCpID(pcpID: payID)
                    await MainActor.run {
                        self.upgrade()
                    }
                } catch {
                    await MainActor.run {
                        self.logger.logE("UpgradeViewModelImpl", "Failed to post pcpID")
                        self.upgrade()
                    }
                }
            }
        } else {
            logger.logE("UpgradeViewModelImpl", "No pcpID now upgrading.")
            upgrade()
        }
    }

    private func listenPushNotificationPayload() {
        pushNotificationManager.notification.sink { [weak self] payload in
            self?.pushNotificationPayload = payload
        }.store(in: &cancellables)
    }

    func failedToPurchase() {
        logger.logE("UpgradeViewModelImpl", "Failed to complete transaction.")
        upgradeState.onNext(.error("Failed to complete transaction."))
    }

    func unableToMakePurchase() {
        logger.logE("UpgradeViewModelImpl", "Failed to complete transaction.")
        upgradeState.onNext(.error("Failed to complete transaction."))
    }

    func setVerifiedTransaction(transaction: UncompletedTransactions?, error: String?) {
        DispatchQueue.main.async { [weak self] in
            if transaction == nil {
                self?.logger.logE("UpgradeViewModelImpl", error ?? "Failed to restore transaction.")
                self?.upgradeState.onNext(.error(error ?? "Failed to restore transaction."))
            } else {
                self?.logger.logD("UpgradeViewModelImpl", "Successfully verified item: \(transaction?.description ?? "")")
                self?.upgrade()
            }
        }
    }

    func failedToLoadProducts() {
        logger.logE("UpgradeViewModelImpl", "Failed to load products. Check your network and try again.")
        showProgress.onNext(false)
        upgradeState.onNext(.error("Failed to load products. Check your network and try again."))
    }

    func unableToRestorePurchase(error: any Error) {
        logger.logE("UpgradeViewModelImpl", "Unable to restore purchase. \(error)")
        if let err = error as? URLError, err.code == URLError.Code.notConnectedToInternet {
            upgradeState.onNext(.error(Errors.noNetwork.description))
        } else if error is URLError {
            upgradeState.onNext(.error(Errors.unknownError.description))
        } else {
            upgradeState.onNext(.error(TextsAsset.PurchaseRestoredAlert.error))
        }
    }

    func dismissWith(action _: ConfirmEmailAction) {}
}

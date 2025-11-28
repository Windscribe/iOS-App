//
//  PlanUpgradeViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-01-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import Foundation
import RxSwift
import StoreKit

protocol PlanUpgradeViewModel {
    var upgradeState: BehaviorSubject<PlanUpgradeState?> { get }
    var plans: BehaviorSubject<PlanTypes?> { get }
    var upgradeRouteState: BehaviorSubject<RouteID?> { get }
    var restoreState: BehaviorSubject<PlanRestoreState?> { get }
    var showProgress: BehaviorSubject<Bool> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }

    func loadPlans(promo: String?, id: String?)
    func continuePayButtonTapped()
    func restoreButtonTapped()
    func setSelectedPlan(plan: WindscribeInAppProduct)
    func showAlert(title: String, message: String)
    func showAlert(title: String, message: String, completion: @escaping () -> Void)
    func failedToLoadProducts()
    func navigateToSignUp(from controller: WSUIViewController)
    func routeTo(to: RouteID, from: WSUIViewController)
}

class DefaultUpgradePlanViewModel: PlanUpgradeViewModel {

    // MARK: Dependencies

    private let alertManager: AlertManagerV2
    private let localDatabase: LocalDatabase
    private let apiManager: APIManager
    private let upgradeRouter: UpgradeRouter
    private let sessionManager: SessionManager
    private let userSessionRepository: UserSessionRepository
    private let preferences: Preferences
    private var inAppPurchaseManager: InAppPurchaseManager
    private let pushNotificationManager: PushNotificationManager
    private let mobilePlanRepository: MobilePlanRepository
    private let logger: FileLogger

    // MARK: Reactive Properties

    let upgradeState: BehaviorSubject<PlanUpgradeState?> = BehaviorSubject(value: nil)
    let showProgress: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    let plans: BehaviorSubject<PlanTypes?> = BehaviorSubject(value: nil)
    let upgradeRouteState: BehaviorSubject<RouteID?> = BehaviorSubject(value: nil)
    let restoreState: BehaviorSubject<PlanRestoreState?> = BehaviorSubject(value: nil)
    let isDarkMode: CurrentValueSubject<Bool, Never>

    // MARK: Internal

    private var pushNotificationPayload: PushNotificationPayload?
    private var pcpID: String?
    private var selectedPlan: WindscribeInAppProduct?
    private var mobilePlans: [MobilePlan]?
    private let disposeBag = DisposeBag()

    init(alertManager: AlertManagerV2,
         localDatabase: LocalDatabase,
         apiManager: APIManager,
         upgradeRouter: UpgradeRouter,
         sessionManager: SessionManager,
         preferences: Preferences,
         inAppPurchaseManager: InAppPurchaseManager,
         pushNotificationManager: PushNotificationManager,
         mobilePlanRepository: MobilePlanRepository, logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         userSessionRepository: UserSessionRepository) {
        self.alertManager = alertManager
        self.localDatabase = localDatabase
        self.apiManager = apiManager
        self.upgradeRouter = upgradeRouter
        self.sessionManager = sessionManager
        self.preferences = preferences
        self.inAppPurchaseManager = inAppPurchaseManager
        self.pushNotificationManager = pushNotificationManager
        self.mobilePlanRepository = mobilePlanRepository
        self.logger = logger
        self.userSessionRepository = userSessionRepository
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        self.inAppPurchaseManager.delegate = self
    }

    private func saveAppleData(appleID: String?, appleData: String?, appleSig: String?) {
        DispatchQueue.main.async {
            self.preferences.saveActiveAppleID(id: appleID)
            self.preferences.saveActiveAppleData(data: appleData)
            self.preferences.saveActiveAppleSig(sig: appleSig)
        }
    }

    func loadPlans(promo: String?, id: String?) {
        var promoCode = promo
        pcpID = id

        // If no promo provided, check if there's a saved promo from push notification
        // This makes the promo "stick" for the entire app session
        if promoCode == nil, let payload = pushNotificationManager.notification.value, payload.type == "promo" {
            logger.logD("DefaultUpgradePlanViewModel", "No promo provided, using saved promo from push notification")
            promoCode = payload.promoCode
            pcpID = payload.pcpid
        }

        logger.logD("DefaultUpgradePlanViewModel", "Loading billing plans. Promo: \(promoCode ?? "N/A"), PCPID: \(pcpID ?? "N/A")")

        showProgress.onNext(true)

        Task { @MainActor in
            do {
                let mobilePlans = try await mobilePlanRepository.getMobilePlans(promo: promoCode)

                for plan in mobilePlans {
                    let discount = plan.discount >= 0 ? "\(plan.discount)%" : "N/A"
                    logger.logD(
                        "DefaultUpgradePlanViewModel",
                        "Plan: \(plan.name) Ext: \(plan.extId) Duration: \(plan.duration) Discount: \(discount)")
                }
                self.mobilePlans = mobilePlans
                showProgress.onNext(false)
                if mobilePlans.count > 0 {
                    inAppPurchaseManager.fetchAvailableProducts(productIDs: mobilePlans.map { $0.extId })
                }
            } catch {
                logger.logE("DefaultUpgradePlanViewModel", "Failed to load mobile plans: \(error)")
                showProgress.onNext(false)
            }
        }
    }

    func continuePayButtonTapped() {
        logger.logD("DefaultUpgradePlanViewModel", "User tapped to upgrade.")
        upgradeState.onNext(.loading)
        if let selectedPlan = selectedPlan {
            inAppPurchaseManager.purchase(windscribeInAppProduct: selectedPlan)
        }
    }

    func restoreButtonTapped() {
        logger.logD("DefaultUpgradePlanViewModel", "User tapped to restore purchases.")
        upgradeState.onNext(.loading)
        inAppPurchaseManager.restorePurchase()
    }

    func setSelectedPlan(plan: WindscribeInAppProduct) {
        logger.logD("DefaultUpgradePlanViewModel", "Selected plan: \(plan.planLabel)")
        selectedPlan = plan
    }

    func showAlert(title: String, message: String) {
        alertManager.showSimpleAlert(
            viewController: nil, title: title, message: message, buttonText: TextsAsset.okay)
    }

    func showAlert(title: String, message: String, completion: @escaping () -> Void) {
        alertManager.showSimpleAlert(
            viewController: nil, title: title, message: message, buttonText: TextsAsset.okay, completion: completion)
    }

    func routeTo(to: RouteID, from: WSUIViewController) {
        upgradeRouter.routeTo(to: to, from: from)
    }

    func navigateToSignUp(from controller: WSUIViewController) {
        upgradeRouter.goToSignUp(viewController: controller, claimGhostAccount: true)
    }

    private func upgrade() {
        self.logger.logI("DefaultUpgradePlanViewModel", "Getting new session.")
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                try await sessionManager.updateSession()
                let session = userSessionRepository.sessionModel
                self.logger.logI("DefaultUpgradePlanViewModel", "Received updated session.")
                self.upgradeState.onNext(.success(session?.isUserGhost ?? false))
            } catch {
                await MainActor.run {
                    self.logger.logE("DefaultUpgradePlanViewModel", "Failure to update session. \(error.localizedDescription)")
                    self.upgradeState.onNext(.success(false))
                }
            }
        }
    }

    private func postpcpID() {
        if let payID = pcpID {
            logger.logD("DefaultUpgradePlanViewModel", "Posting pcpID")
            Task { [weak self] in
                guard let self = self else { return }

                do {
                    _ = try await self.apiManager.postBillingCpID(pcpID: payID)
                    await MainActor.run {
                        self.upgrade()
                    }
                } catch {
                    await MainActor.run {
                        self.logger.logE("DefaultUpgradePlanViewModel", "Failed to post pcpID \(error.localizedDescription)")
                        self.upgrade()
                    }
                }
            }
        } else {
            logger.logE("DefaultUpgradePlanViewModel", "No pcpID now upgrading.")
            upgrade()
        }
    }
}

// MARK: - InAppPurchaseManagerDelegate

extension DefaultUpgradePlanViewModel: InAppPurchaseManagerDelegate {
    func didFetchAvailableProducts(windscribeProducts: [WindscribeInAppProduct]) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            showProgress.onNext(false)

            if let discountedWindscribePlan = mobilePlans?.first(where: { $0.discount >= 0}),
                let discountedApplePlan = windscribeProducts.first(where: {$0.extId == discountedWindscribePlan.extId}) {
                plans.onNext(.discounted(discountedApplePlan, discountedWindscribePlan))
            } else if windscribeProducts.count > 0 && windscribeProducts.count == mobilePlans?.count {
                plans.onNext(.standardPlans(windscribeProducts, mobilePlans ?? []))
            } else {
                plans.onNext(.unableToLoad)
            }
        }
    }

    func purchasedSuccessfully(transaction _: SKPaymentTransaction, appleID: String, appleData: String, appleSIG: String) {
        logger.logD("DefaultUpgradePlanViewModel", "Purchase successful.")

        Task { [weak self] in
            guard let self = self else { return }

            do {
                _ = try await self.apiManager.verifyApplePayment(appleID: appleID, appleData: appleData, appleSIG: appleSIG)
                await MainActor.run {
                    self.logger.logD("DefaultUpgradePlanViewModel", "Purchase verified successfully")
                    self.saveAppleData(appleID: nil, appleData: nil, appleSig: nil)
                    self.postpcpID()
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("DefaultUpgradePlanViewModel", "Failed to verify payment and saving for later. \(error)")
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

    func failedToPurchase() {
        logger.logE("DefaultUpgradePlanViewModel", "Failed to complete transaction.")
        upgradeState.onNext(
            .titledError(TextsAsset.UpgradeView.planBenefitTransactionFailedAlertTitle,
                         TextsAsset.UpgradeView.planBenefitTransactionFailedAlert))
    }

    func unableToMakePurchase() {
        logger.logE("DefaultUpgradePlanViewModel", "Failed to complete transaction.")
        upgradeState.onNext(.error(TextsAsset.UpgradeView.planBenefitTransactionFailedAlertTitle))
    }

    func failedCanceledByUser() {
        logger.logE("DefaultUpgradePlanViewModel", "Failed to complete transaction. Purchase canceled by user.")
        // Upgrade state will not send an error here so dismiss screen will not show alert
        upgradeState.onNext(.none)
    }

    func failedDueToNetworkIssue() {
        logger.logE("DefaultUpgradePlanViewModel", "Failed to complete transaction. Problem with internet connection.")
        upgradeState.onNext(.error(TextsAsset.UpgradeView.planBenefitTransactionFailedAlertTitle))
    }

    func setVerifiedTransaction(transaction: UncompletedTransactions?, error: String?) {
        DispatchQueue.main.async { [weak self] in
            if transaction == nil {
                self?.logger.logE("PlanUpgradeViewModel.", error ?? "Failed to restore transaction.")
                self?.upgradeState.onNext(.error(error ?? TextsAsset.UpgradeView.planBenefitTransactionFailedRestoreTitle))
            } else {
                self?.logger.logD("PlanUpgradeViewModel.", "Successfully verified item: \(transaction?.description ?? "")")
                self?.upgrade()
            }
        }
    }

    func failedToLoadProducts() {
        logger.logE("DefaultUpgradePlanViewModel", "Failed to load products. Check your network and try again.")
        showProgress.onNext(false)
        upgradeState.onNext(.error(TextsAsset.UpgradeView.planBenefitNetworkProblemTitle))
    }

    func unableToRestorePurchase(error: any Error) {
        logger.logE("DefaultUpgradePlanViewModel", "Unable to restore purchase. \(error)")
        if let err = error as? URLError, err.code == URLError.Code.notConnectedToInternet {
            upgradeState.onNext(.error(Errors.noNetwork.description))
        } else if error is URLError {
            upgradeState.onNext(.error(Errors.unknownError.description))
        } else {
            upgradeState.onNext(.error(TextsAsset.PurchaseRestoredAlert.error))
        }
    }
}

//
//  UpgradeViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/02/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import StoreKit

enum UpgradeState {
    case success(Bool)
    case loading
    case error(String)
}

enum Plans {
    case discounted(WindscribeInAppProduct, MobilePlanModel)
    case standardPlans([WindscribeInAppProduct], [MobilePlanModel])
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
    var upgradeState: CurrentValueSubject<UpgradeState?, Never> { get }
    var plans: CurrentValueSubject<Plans?, Never> { get }
    var upgradeRouteState: CurrentValueSubject<RouteID?, Never> { get }
    var restoreState: CurrentValueSubject<RestoreState?, Never> { get }
    var showProgress: CurrentValueSubject<Bool, Never> { get }
    var showFreeDataOption: CurrentValueSubject<Bool, Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }

    func loadPlans(promo: String?, id: String?)
    func continuePayButtonTapped()
    func continueFreeButtonTapped()
    func restoreButtonTapped()
    func setSelectedPlan(plan: WindscribeInAppProduct)
}

class UpgradeViewModelImpl: UpgradeViewModel, InAppPurchaseManagerDelegate, ConfirmEmailViewControllerDelegate {
    let alertManager: AlertManager
    let apiManager: APIManager
    let sessionManager: SessionManager
    let userSessionRepository: UserSessionRepository
    let preferences: Preferences
    var inAppPurchaseManager: InAppPurchaseManager
    let pushNotificationManager: PushNotificationManager
    let mobilePlanRepository: MobilePlanRepository
    let logger: FileLogger

    let upgradeState = CurrentValueSubject<UpgradeState?, Never>(nil)
    let showProgress = CurrentValueSubject<Bool, Never>(false)
    var plans = CurrentValueSubject<Plans?, Never>(nil)
    var upgradeRouteState = CurrentValueSubject<RouteID?, Never>(nil)
    var restoreState = CurrentValueSubject<RestoreState?, Never>(nil)
    var showFreeDataOption = CurrentValueSubject<Bool, Never>(false)
    let isDarkMode: CurrentValueSubject<Bool, Never>

    var selectedPlan: WindscribeInAppProduct?
    private var cancellables = Set<AnyCancellable>()
    var pcpID: String?
    var pushNotificationPayload: PushNotificationPayload?
    private var mobilePlans: [MobilePlanModel]?

    init(alertManager: AlertManager,
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
            showFreeDataOption.send(session.isUserGhost || !session.hasUserAddedEmail || (session.hasUserAddedEmail && session.userNeedsToConfirmEmail))
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
        showProgress.send(true)
        Task { @MainActor in
            do {
                let mobilePlans = try await mobilePlanRepository.getMobilePlans(promo: promoCode)

                for p in mobilePlans {
                    let discount = p.discount >= 0 ? "\(p.discount)%" : "N/A"
                    logger.logD("UpgradeViewModelImpl", "Plan: \(p.name) Ext: \(p.extId) Duration: \(p.duration) Discount: \(discount)")
                }
                self.mobilePlans = mobilePlans
                showProgress.send(false)
                if mobilePlans.count > 0 {
                    inAppPurchaseManager.fetchAvailableProducts(productIDs: mobilePlans.map { $0.extId })
                }
            } catch {
                logger.logE("UpgradeViewModelImpl", "Failed to load mobile plans: \(error)")
                showProgress.send(false)
            }
        }
    }

    func continuePayButtonTapped() {
        logger.logD("UpgradeViewModelImpl", "User tapped to upgrade.")
        upgradeState.send(.loading)
        if let selectedPlan = selectedPlan {
            inAppPurchaseManager.purchase(windscribeInAppProduct: selectedPlan)
        }
    }

    func continueFreeButtonTapped() {
        logger.logD("UpgradeViewModelImpl", "User tapped to get free data.")
        if userSessionRepository.sessionModel?.hasUserAddedEmail == true && userSessionRepository.sessionModel?.emailStatus == false {
            upgradeRouteState.send(RouteID.confirmEmail(delegate: self))
        } else if userSessionRepository.sessionModel?.hasUserAddedEmail == false && userSessionRepository.sessionModel?.isUserGhost == false {
            upgradeRouteState.send(RouteID.enterEmail)
        } else {
            upgradeRouteState.send(RouteID.signup(claimGhostAccount: true))
        }
    }

    func restoreButtonTapped() {
        logger.logD("UpgradeViewModelImpl", "User tapped to restore purchases.")
        upgradeState.send(.loading)
        inAppPurchaseManager.restorePurchase()
    }

    func setSelectedPlan(plan: WindscribeInAppProduct) {
        logger.logD("UpgradeViewModelImpl", "Selected plan: \(plan.planLabel)")
        selectedPlan = plan
    }

    func didFetchAvailableProducts(windscribeProducts: [WindscribeInAppProduct]) {
        DispatchQueue.main.async { [self] in
            showProgress.send(false)
            if let discountedWindscribePlan = mobilePlans?.first(where: { $0.discount >= 0}), let discountedApplePlan = windscribeProducts.first(where: {$0.extId == discountedWindscribePlan.extId}) {
                plans.send(.discounted(discountedApplePlan, discountedWindscribePlan))
            } else if windscribeProducts.count > 0 && windscribeProducts.count == mobilePlans?.count {
                plans.send(.standardPlans(windscribeProducts, mobilePlans ?? []))
            } else {
                plans.send(.unableToLoad)
            }
        }
    }

    func failedCanceledByUser() {
        logger.logE("UpgradeViewModelImpl", "Failed to complete transaction. Purchase canceled by user.")
        // Upgrade state will not send an error here so dismiss screen will not show alert
        upgradeState.send(.none)
    }

    func failedDueToNetworkIssue() {
        logger.logE("UpgradeViewModelImpl", "Failed to complete transaction. Problem with internet connection.")
        upgradeState.send(.error(TextsAsset.UpgradeView.planBenefitTransactionFailedAlertTitle))
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
                            self.upgradeState.send(.error(error.errorMessage ?? ""))
                        default:
                            self.upgradeState.send(.error(error.description))
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
                self.upgradeState.send(.success(session?.isUserGhost ?? false))
            } catch {
                await MainActor.run {
                    self.logger.logE("UpgradeViewModelImpl", "Failure to update session.")
                    self.upgradeState.send(.success(false))
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
        upgradeState.send(.error("Failed to complete transaction."))
    }

    func unableToMakePurchase() {
        logger.logE("UpgradeViewModelImpl", "Failed to complete transaction.")
        upgradeState.send(.error("Failed to complete transaction."))
    }

    func setVerifiedTransaction(transaction: UncompletedTransactions?, error: String?) {
        DispatchQueue.main.async { [weak self] in
            if transaction == nil {
                self?.logger.logE("UpgradeViewModelImpl", error ?? "Failed to restore transaction.")
                self?.upgradeState.send(.error(error ?? "Failed to restore transaction."))
            } else {
                self?.logger.logD("UpgradeViewModelImpl", "Successfully verified item: \(transaction?.description ?? "")")
                self?.upgrade()
            }
        }
    }

    func failedToLoadProducts() {
        logger.logE("UpgradeViewModelImpl", "Failed to load products. Check your network and try again.")
        showProgress.send(false)
        upgradeState.send(.error("Failed to load products. Check your network and try again."))
    }

    func unableToRestorePurchase(error: any Error) {
        logger.logE("UpgradeViewModelImpl", "Unable to restore purchase. \(error)")
        if let err = error as? URLError, err.code == URLError.Code.notConnectedToInternet {
            upgradeState.send(.error(Errors.noNetwork.description))
        } else if error is URLError {
            upgradeState.send(.error(Errors.unknownError.description))
        } else {
            upgradeState.send(.error(TextsAsset.PurchaseRestoredAlert.error))
        }
    }

    func dismissWith(action _: ConfirmEmailAction) {}
}

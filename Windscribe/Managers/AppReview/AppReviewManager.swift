//
//  AppReviewManager.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-11.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import Foundation
import RxSwift
import StoreKit

class AppReviewManager: AppReviewManaging {

    /// A main criterias that should be satisfied to show app rating
    enum AppReviewCriteriaType: CaseIterable {
        case timeElapseStatus
        case bandwithUsage
        case loggedStatus
        case userActiveStatus
    }

    let preferences: Preferences
    let localDatabase: LocalDatabase
    let logger: FileLogger
    var reviewCriteria: [AppReviewCriteriaType]
    private var cancellables = Set<AnyCancellable>()
    let reviewRequestTrigger = PublishSubject<Void>()

    init (preferences: Preferences, localDatabase: LocalDatabase, logger: FileLogger) {
        self.preferences = preferences
        self.localDatabase = localDatabase
        self.logger = logger

        // Criteria for requesting review can be changed dynamically
        // Add Delete from this list to change app review criteria to be satisfied
        reviewCriteria = [AppReviewCriteriaType.timeElapseStatus,
                          AppReviewCriteriaType.bandwithUsage,
                          AppReviewCriteriaType.loggedStatus,
                          AppReviewCriteriaType.userActiveStatus]
    }

    func requestReviewIfAvailable(session: Session?) {
        guard shouldShowReviewRequest(session: session) else {
            logger.logD("AppReviewManager", "Rate Dialog: Do not show! All of the review request criterias shall be met.")
            return
        }

        promptReview()
    }

    func shouldShowReviewRequest(session: Session?) -> Bool {
        // User Session is necessary to detect user status
        guard let session = session else {
            logger.logD("AppReviewManager", "Rate Dialog: Do not show, no session available")
            return false
        }

        // All of the criterias should be met
        let criteriaSatisfied = reviewCriteria.allSatisfy({ criteria in
            checkReviewCriteriasSatisfied(for: criteria, session: session)
        })

        return criteriaSatisfied
    }

    /// This method is for checking App Review Sub Criteria is satisfied for a type
    /// - Parameter type: Main-criteria type
    /// - Returns:Boolean value showing particular criteria is satisfied
    private func checkReviewCriteriasSatisfied(for type: AppReviewCriteriaType, session: Session) -> Bool {
      switch type {
      case .timeElapseStatus:
          return checkTimeElapseStatus()
      case .bandwithUsage:
          return checkUsageBandwithStatus(session: session)
      case .loggedStatus:
          return checkLoggedStatus()
      case .userActiveStatus:
          return checkActiveStatus(session: session)
      }
    }

    /// Step 1
    /// Time elapsed since last dialog appeared is more than 180 days
    /// - Returns: If user prompted with review more than 180 days ago
    private func checkTimeElapseStatus() -> Bool {
        guard !hasReviewRequestedBefore() else {
            // Review has requested before check if it is more than 180 days
            logger.logD("AppReviewManager", "Rate Dialog: The dialog has been shown before, lets check if it was more than 180 days ago.")

            guard let dateLastShown = preferences.getWhenRateUsPopupDisplayed() else {
                logger.logD("AppReviewManager", "Rate Dialog: We don't have a date for last show, but we have the information that is was shown, let's try showing again.")
                return true
            }

            guard daysSinceLastReviewRequest(dateLastShown: dateLastShown) > 180 else {
                logger.logD("AppReviewManager", "Rate Dialog: Do not show! Rate dialog was shown less than 180 days ago.")
                return false
            }

            return true
        }

        // Review has not requested before so request it
        return true
    }

    /// Step 2
    /// User used at least 1 gb
    /// - Returns: If user used soem amount of data that will be enough for rating
    private func checkUsageBandwithStatus(session: Session) -> Bool {
        guard session.getDataUsedInMB() >= 1024 else {
            return false
        }

        return true
    }

    /// Step 3
    /// User first time logged in more than 2 days ago (not registered)
    /// - Returns: If user is older than 2 days old
    private func checkLoggedStatus() -> Bool {
        guard daysSinceLogin() >= 2 else {
            logger.logD("AppReviewManager", "Rate Dialog: Do not show! It has been less than 2 days since first time login")
            return false
        }

        return true
    }

    /// Step 4 - Step 5
    /// User not banned
    /// User not out of data
    /// - Returns: If user is in active status
    private func checkActiveStatus (session: Session) -> Bool {
        // Checking user status
        // User is not banned (session status ≠ 3)
        // User has some data left (session status ≠ 2)
        guard session.status == 1 else {
            let statusDescription = session.status == 2 ? "Out of Data" :
                                    (session.status == 3 ? "Banned" : "Unknown: \(session.status)")
            logger.logD("AppReviewManager", "Rate Dialog: Do not show! Session not in valid state: \(statusDescription)")

            return false
        }

        logger.logD("AppReviewManager", "Rate Dialog: Show Dialog! Session is in scope also valid")
        return true
    }
}

// MARK: - Review Status Helper

extension AppReviewManager {

    private func daysSinceLogin() -> Int {
        let dateLoggedIn = preferences.getLoginDate() ?? Date()
        return dateLoggedIn.daysSince
    }

    private func hasReviewRequestedBefore() -> Bool {
        return preferences.getRateUsActionCompleted()
    }

    private func daysSinceLastReviewRequest(dateLastShown: Date) -> Int {
        let timeSinceLastTime = dateLastShown.daysSince
        logger.logD("AppReviewManager", "Rate Dialog: Rate Dialog last shown at: \(dateLastShown), it was shown \(timeSinceLastTime) days ago.")

        return timeSinceLastTime
    }
}

// MARK: Review Display Helper

extension AppReviewManager {

    private func promptReview() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            logger.logD("AppReviewManager", "Rate Dialog: No active UIWindowScene found.")
            return
        }
#if os(iOS)
        // Observe if the SKStoreReviewPresentationWindow appears
        let reviewPromptDetected = observeReviewWindow()

        // Request the system review prompt
        SKStoreReviewController.requestReview(in: scene)

        // Wait for 0.5 seconds to allow the system to display the review prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }

            // Save review prompt display timestamp and completion state
            self.preferences.saveWhenRateUsPopupDisplayed(date: Date())
            self.preferences.saveRateUsActionCompleted(bool: true)

            // If a review prompt was shown, do nothing further
            if reviewPromptDetected.value {
                logger.logD("AppReviewManager", "Rate Dialog: Review prompt was likely SHOWN (new window detected).")
                return
            }

            // If no review prompt was detected, open the App Store review page
            logger.logD("AppReviewManager", "Rate Dialog: Review prompt was NOT shown (no new window appeared).")
            self.promptReviewWithConfirmation()
        }

        #elseif os(tvOS)
        // SKStoreReviewController is not available on tvOS, so redirect to the App Store review page
        logger.logD("AppReviewManager", "Rate Dialog: SKStoreReviewController is not available on tvOS, opening App Store review page.")
        promptReviewWithConfirmation()
        #endif
    }

    private func observeReviewWindow() -> CurrentValueSubject<Bool, Never> {
        let reviewPromptDetected = CurrentValueSubject<Bool, Never>(false)

        // Listen for any new windows becoming visible
        NotificationCenter.default.publisher(for: UIWindow.didBecomeVisibleNotification)
            .compactMap { $0.object as? UIWindow }
            // Filter only SKStoreReviewPresentationWindow instances
            .filter { $0.isKind(of: NSClassFromString("SKStoreReviewPresentationWindow")!) }
            .sink { _ in
                // If detected, mark that the review prompt was shown
                reviewPromptDetected.send(true)
                self.logger.logD("AppReviewManager", "Rate Dialog: Review prompt was SHOWN - SKStoreReviewPresentationWindow detected.")
            }
            .store(in: &cancellables)

        return reviewPromptDetected
    }

    internal func promptReviewWithConfirmation() {
         reviewRequestTrigger.onNext(())
     }

    func openAppStoreForReview() {
        let appID = DefaultValues.appID
        let urlString = "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review"

        // Open the App Store review page if the URL is valid and can be opened
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

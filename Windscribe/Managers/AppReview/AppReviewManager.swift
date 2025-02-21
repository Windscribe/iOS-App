//
//  AppReviewManager.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-11.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import StoreKit

protocol AppReviewManager {
    var preferences: Preferences { get }
    var localDatabase: LocalDatabase { get }
    var logger: FileLogger { get }

    func requestReviewIfAvailable(session: Session?)
}

class DefaultAppReviewManager: AppReviewManager {

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
            logger.logD(self, "Rate Dialog: Do not show! All of the review request criterias shall be met.")
            return
        }

        promptReview()
    }

    func shouldShowReviewRequest(session: Session?) -> Bool {
        // User Session is necessary to detect user status
        guard let session = session else {
            logger.logD(self, "Rate Dialog: Do not show, no session available")
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
            logger.logD(self, "Rate Dialog: The dialog has been shown before, lets check if it was more than 180 days ago.")

            guard let dateLastShown = preferences.getWhenRateUsPopupDisplayed() else {
                logger.logD(self, "Rate Dialog: We don't have a date for last show, but we have the information that is was shown, let's try showing again.")
                return true
            }

            guard daysSinceLastReviewRequest(dateLastShown: dateLastShown) > 180 else {
                logger.logD(self, "Rate Dialog: Do not show! Rate dialog was shown less than 180 days ago.")
                return false
            }

            logger.logD(self, "Rate Dialog: Show Dialog! User has seen the dialog, but more than 30 days ago, lets try again.")
            return true
        }

        // Review has not requested before so request it
        logger.logD(self, "Rate Dialog: The dialog has been shown before, lets check if it was more than 30 days ago.")
        return true
    }

    /// Step 2
    /// User used at least 1 gb
    /// - Returns: If user used soem amount of data that will be enough for rating
    private func checkUsageBandwithStatus(session: Session) -> Bool {
        guard session.getDataUsedInMB() >= 1024 else {
            logger.logD(self, "Rate Dialog: Do not show! User has not spent 1Gb yet")
            return false
        }

        return true
    }

    /// Step 3
    /// User first time logged in more than 2 days ago (not registered)
    /// - Returns: If user is older than 2 days old
    private func checkLoggedStatus() -> Bool {
        guard daysSinceLogin() >= 2 else {
            logger.logD(self, "Rate Dialog: Do not show! It has been less than 2 days since first time login")
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
            logger.logD(self, "Rate Dialog: Do not show! Session not in valid state: \(statusDescription)")

            return false
        }

        logger.logD(self, "Rate Dialog: Show Dialog! Session is in scope also valid")
        return true
    }
}

// MARK: - Review Status Helper

extension DefaultAppReviewManager {

    private func daysSinceLogin() -> Int {
        let dateLoggedIn = preferences.getLoginDate() ?? Date()
        return dateLoggedIn.daysSince
    }

    private func hasReviewRequestedBefore() -> Bool {
        return preferences.getRateUsActionCompleted()
    }

    private func daysSinceLastReviewRequest(dateLastShown: Date) -> Int {
        let timeSinceLastTime = dateLastShown.daysSince
        logger.logD(self, "Rate Dialog: Rate Dialog last shown at: \(dateLastShown), it was shown \(timeSinceLastTime) days ago.")

        return timeSinceLastTime
    }
}

// MARK: Review Display Helper

extension DefaultAppReviewManager {
    private func promptReview() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            logger.logD(self, "Rate Dialog: No active UIWindowScene found.")
            return
        }
#if os(iOS)
        // Capture the current window count before calling requestReview
        let windowCountBefore = UIApplication.shared.windowCount
        requestReview(scene: scene)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }

            self.preferences.saveWhenRateUsPopupDisplayed(date: Date())
            self.preferences.saveRateUsActionCompleted(bool: true)

            // Capture the current window count after calling requestReview
            let windowCountAfter = UIApplication.shared.windowCount
            // And check if rate dialog is shown
            let isRateDialogShown = windowCountAfter > windowCountBefore

            guard !isRateDialogShown else {
                logger.logD(self, "Rate Dialog: Review prompt was likely SHOWN (new window detected).")
                return
            }

            logger.logD(self, "Rate Dialog: Review prompt was NOT shown (no new window appeared).")
            self.openAppStoreForReview()
        }
#elseif os(tvOS)
        logger.logD(self, "Rate Dialog: SKStoreReviewController is not available on tvOS, opening App Store review page.")
        openAppStoreForReview()
#endif
    }

    private func requestReview(scene: UIWindowScene) {
        if #available(iOS 14.0, *) {
            SKStoreReviewController.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview()
        }
    }

    private func openAppStoreForReview() {
        let appID = DefaultValues.appID
        let urlString = "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review"

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

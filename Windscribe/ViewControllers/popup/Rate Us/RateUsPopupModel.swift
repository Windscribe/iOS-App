//
//  RateUsPopupModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 15/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit

protocol RateUsPopupModelType {
    func setDate()
    func setRateUsActionCompleted()
    func getNativeRateUsDisplayCount() -> Int?
    func increaseNativeRateUsPopupDisplayCount()
    func openAppStoreRattingView()
}

class RateUsPopupModel: RateUsPopupModelType {
    var preferences: Preferences

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func setDate() {
        preferences.saveWhenRateUsPopupDisplayed(date: Date())
    }

    func setRateUsActionCompleted() {
        preferences.saveRateUsActionCompleted(bool: true)
    }

    func getNativeRateUsDisplayCount() -> Int? {
       return preferences.getNativeRateUsPopupDisplayCount()
    }

    func increaseNativeRateUsPopupDisplayCount() {
        let count = (getNativeRateUsDisplayCount() ?? 0) + 1
        preferences.saveNativeRateUsPopupDisplayCount(count: count)
    }

    func openAppStoreRattingView() {
        let url = "itms-apps://apps.apple.com/app/id1129435228?action=write-review"
        guard let writeReviewURL = URL(string: url) else {
            return
        }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
}

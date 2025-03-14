//
//  AppReviewManaging.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol AppReviewManaging {
    var preferences: Preferences { get }
    var localDatabase: LocalDatabase { get }
    var logger: FileLogger { get }

    var reviewRequestTrigger: PublishSubject<Void> { get }

    func requestReviewIfAvailable(session: Session?)
    func promptReviewWithConfirmation()
    func openAppStoreForReview()
    func shouldShowReviewRequest(session: Session?) -> Bool
}

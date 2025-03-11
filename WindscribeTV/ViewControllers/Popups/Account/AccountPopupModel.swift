//
//  AccountPopupModel.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 03/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

protocol AccountPopupModelType {
    var imageName: BehaviorSubject<String> { get }
    var title: BehaviorSubject<String> { get }
    var description: BehaviorSubject<String> { get }
    var actionButtonTitle: BehaviorSubject<String> { get }
    var cancelButtonTitle: BehaviorSubject<String> { get }
    func action(viewController: UIViewController)
    func getNextResetDate() -> String
}

protocol BannedAccountPopupModelType: AccountPopupModelType {}
class BannedAccountPopupModel: AccountPopupModel, BannedAccountPopupModelType {
    override func bindModel() {
        imageName.onNext(ImagesAsset.Garry.angry)
        title.onNext(TextsAsset.Banned.title)
        description.onNext(TextsAsset.Banned.description)
        actionButtonTitle.onNext(TextsAsset.Banned.action)
        cancelButtonTitle.onNext("")
    }

    override func action(viewController _: UIViewController) {}
}

protocol OutOfDataAccountPopupModelType: AccountPopupModelType {}
class OutOfDataAccountPopupModel: AccountPopupModel, OutOfDataAccountPopupModelType {
    override func bindModel() {
        imageName.onNext(ImagesAsset.Garry.noData)
        title.onNext(TextsAsset.OutOfData.title)
        description.onNext("\(TextsAsset.OutOfData.description) \(getNextResetDate())")
        actionButtonTitle.onNext(TextsAsset.OutOfData.action)
        cancelButtonTitle.onNext(TextsAsset.OutOfData.cancel)
    }
}

protocol ProPlanExpiredAccountPopupModelType: AccountPopupModelType {}
class ProPlanExpiredAccountPopupModel: AccountPopupModel, ProPlanExpiredAccountPopupModelType {
    override func bindModel() {
        imageName.onNext(ImagesAsset.Garry.sad)
        title.onNext(TextsAsset.ProPlanExpired.title)
        description.onNext(TextsAsset.ProPlanExpired.description)
        actionButtonTitle.onNext(TextsAsset.ProPlanExpired.action)
        cancelButtonTitle.onNext(TextsAsset.ProPlanExpired.cancel)
    }
}

class AccountPopupModel: AccountPopupModelType {
    // MARK: - Dependencies

    let localDatabase: LocalDatabase
    let imageName = BehaviorSubject<String>(value: "")
    let title = BehaviorSubject<String>(value: "")
    let description = BehaviorSubject<String>(value: "")
    let actionButtonTitle = BehaviorSubject<String>(value: "")
    let cancelButtonTitle = BehaviorSubject<String>(value: "")
    var router: HomeRouter

    init(localDatabase: LocalDatabase, router: HomeRouter) {
        self.localDatabase = localDatabase
        self.router = router
        bindModel()
    }

    func getNextResetDate() -> String {
        return localDatabase.getSessionSync()?.getNextReset() ?? ""
    }

    func bindModel() {
        fatalError("Subclasses need to implement the `bindModel()` method.")
    }

    func action(viewController: UIViewController) {
        router.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil), from: viewController)
    }
}

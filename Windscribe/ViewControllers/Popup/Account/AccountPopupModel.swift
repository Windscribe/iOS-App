//
//  AccountPopupModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 05/04/2024.
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
    var popupRouter: PopupRouter? { get }
    func action(viewController: WSUIViewController)
    func cancel(navigationVC: UINavigationController?)
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

    override func action(viewController _: WSUIViewController) {}
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

    let popupRouter: PopupRouter?, sessionManager: SessionManaging
    let imageName = BehaviorSubject<String>(value: "")
    let title = BehaviorSubject<String>(value: "")
    let description = BehaviorSubject<String>(value: "")
    let actionButtonTitle = BehaviorSubject<String>(value: "")
    let cancelButtonTitle = BehaviorSubject<String>(value: "")

    init(popupRouter: PopupRouter?, sessionManager: SessionManaging) {
        self.popupRouter = popupRouter
        self.sessionManager = sessionManager
        bindModel()
    }

    func getNextResetDate() -> String {
        return sessionManager.session?.getNextReset() ?? ""
    }

    func bindModel() {
        fatalError("Subclasses need to implement the `bindModel()` method.")
    }

    func action(viewController: WSUIViewController) {
        popupRouter?.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil), from: viewController)
    }

    func cancel(navigationVC: UINavigationController?) {
        popupRouter?.dismissPopup(navigationVC: navigationVC)
    }
}

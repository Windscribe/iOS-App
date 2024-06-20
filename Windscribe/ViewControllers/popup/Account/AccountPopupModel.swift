//
//  AccountPopupModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 05/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol AccountPopupModelType {
    var imageName: BehaviorSubject<String> {get}
    var title: BehaviorSubject<String> {get}
    var description: BehaviorSubject<String> {get}
    var actionButtonTitle: BehaviorSubject<String> {get}
    var cancelButtonTitle: BehaviorSubject<String> {get}
    var popupRouter: PopupRouter? {get}
    func action(viewController: WSUIViewController)
    func cancel(navigationVC: UINavigationController?)
    func getNextResetDate() -> String
}

protocol BannedAccountPopupModelType: AccountPopupModelType {}
class BannedAccountPopupModel: AccountPopupModel, BannedAccountPopupModelType {
    override func bindModel() {
        self.imageName.onNext(ImagesAsset.Garry.angry)
        self.title.onNext(TextsAsset.Banned.title)
        self.description.onNext(TextsAsset.Banned.description)
        self.actionButtonTitle.onNext(TextsAsset.Banned.action)
        self.cancelButtonTitle.onNext("")
    }

    override func action(viewController: WSUIViewController) {
    }
}

protocol OutOfDataAccountPopupModelType: AccountPopupModelType {}
class OutOfDataAccountPopupModel: AccountPopupModel, OutOfDataAccountPopupModelType {
    override func bindModel() {
        self.imageName.onNext(ImagesAsset.Garry.noData)
        self.title.onNext(TextsAsset.OutOfData.title)
        self.description.onNext("\(TextsAsset.OutOfData.description) \(getNextResetDate())")
        self.actionButtonTitle.onNext(TextsAsset.OutOfData.action)
        self.cancelButtonTitle.onNext(TextsAsset.OutOfData.cancel)
    }
}

protocol ProPlanExpiredAccountPopupModelType: AccountPopupModelType {}
class ProPlanExpiredAccountPopupModel: AccountPopupModel, ProPlanExpiredAccountPopupModelType {
    override func bindModel() {
        self.imageName.onNext(ImagesAsset.Garry.sad)
        self.title.onNext(TextsAsset.ProPlanExpired.title)
        self.description.onNext(TextsAsset.ProPlanExpired.description)
        self.actionButtonTitle.onNext(TextsAsset.ProPlanExpired.action)
        self.cancelButtonTitle.onNext(TextsAsset.ProPlanExpired.cancel)
    }
}

class AccountPopupModel: AccountPopupModelType {

    // MARK: - Dependencies
    let popupRouter: PopupRouter?, sessionManager: SessionManagerV2
    let imageName = BehaviorSubject<String>(value: "")
    let title = BehaviorSubject<String>(value: "")
    let description = BehaviorSubject<String>(value: "")
    let actionButtonTitle = BehaviorSubject<String>(value: "")
    let cancelButtonTitle = BehaviorSubject<String>(value: "")

    init(popupRouter: PopupRouter?, sessionManager: SessionManagerV2) {
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
        popupRouter?.dismissPopup(action: .dismiss, navigationVC: navigationVC)
    }
}

//
//  AccountPopupModel.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 03/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UIKit

protocol AccountPopupModelType {
    var imageName: CurrentValueSubject<String, Never> { get }
    var title: CurrentValueSubject<String, Never> { get }
    var description: CurrentValueSubject<String, Never> { get }
    var actionButtonTitle: CurrentValueSubject<String, Never> { get }
    var cancelButtonTitle: CurrentValueSubject<String, Never> { get }
    func action(viewController: UIViewController)
    func getNextResetDate() -> String
}

protocol BannedAccountPopupModelType: AccountPopupModelType {}
class BannedAccountPopupModel: AccountPopupModel, BannedAccountPopupModelType {
    override func bindModel() {
        imageName.send(ImagesAsset.Garry.angry)
        title.send(TextsAsset.Banned.title)
        description.send(TextsAsset.Banned.description)
        actionButtonTitle.send(TextsAsset.Banned.action)
        cancelButtonTitle.send("")
    }

    override func action(viewController _: UIViewController) {}
}

protocol OutOfDataAccountPopupModelType: AccountPopupModelType {}
class OutOfDataAccountPopupModel: AccountPopupModel, OutOfDataAccountPopupModelType {
    override func bindModel() {
        imageName.send(ImagesAsset.Garry.noData)
        title.send(TextsAsset.OutOfData.title)
        description.send("\(TextsAsset.OutOfData.description) \(getNextResetDate())")
        actionButtonTitle.send(TextsAsset.OutOfData.action)
        cancelButtonTitle.send(TextsAsset.OutOfData.cancel)
    }
}

protocol ProPlanExpiredAccountPopupModelType: AccountPopupModelType {}
class ProPlanExpiredAccountPopupModel: AccountPopupModel, ProPlanExpiredAccountPopupModelType {
    override func bindModel() {
        imageName.send(ImagesAsset.Garry.sad)
        title.send(TextsAsset.ProPlanExpired.title)
        description.send(TextsAsset.ProPlanExpired.description)
        actionButtonTitle.send(TextsAsset.ProPlanExpired.action)
        cancelButtonTitle.send(TextsAsset.ProPlanExpired.cancel)
    }
}

class AccountPopupModel: AccountPopupModelType {
    // MARK: - Dependencies

    let userSessionRepository: UserSessionRepository
    let imageName = CurrentValueSubject<String, Never>("")
    let title = CurrentValueSubject<String, Never>("")
    let description = CurrentValueSubject<String, Never>("")
    let actionButtonTitle = CurrentValueSubject<String, Never>("")
    let cancelButtonTitle = CurrentValueSubject<String, Never>("")
    var router: HomeRouter

    init(userSessionRepository: UserSessionRepository, router: HomeRouter) {
        self.userSessionRepository = userSessionRepository
        self.router = router
        bindModel()
    }

    private var session: SessionModel? { userSessionRepository.sessionModel }

    func getNextResetDate() -> String {
        return userSessionRepository.sessionModel?.getNextReset() ?? ""
    }

    func bindModel() {
        fatalError("Subclasses need to implement the `bindModel()` method.")
    }

    func action(viewController: UIViewController) {
        router.routeTo(to: RouteID.upgrade(promoCode: nil, pcpID: nil), from: viewController)
    }
}

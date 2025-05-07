//
//  PopUpMaintenanceLocationModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 15/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol PopUpMaintenanceLocationModelType {
    var topImageName: BehaviorSubject<String> { get }
    var headerLabelTitle: BehaviorSubject<String> { get }
    var subHeaderLabelTitle: BehaviorSubject<String> { get }
    var cancelButtonTitle: BehaviorSubject<String> { get }
    var checkStatusButtonTitle: BehaviorSubject<String> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    func cancel(vc: UIViewController?)
    func checkStatusAction(vc: WSNavigationViewController?)
}

class PopUpMaintenanceLocationModel: PopUpMaintenanceLocationModelType {
    // MARK: - Dependencies

    var topImageName = BehaviorSubject<String>(value: "")
    var headerLabelTitle = BehaviorSubject<String>(value: "")
    var subHeaderLabelTitle = BehaviorSubject<String>(value: "")
    var cancelButtonTitle = BehaviorSubject<String>(value: "")
    var checkStatusButtonTitle = BehaviorSubject<String>(value: "")
    let isDarkMode: BehaviorSubject<Bool>

    init(lookAndFeelRepo: LookAndFeelRepositoryType) {
        isDarkMode = lookAndFeelRepo.isDarkModeSubject
        bindModel()
    }

    private func bindModel() {
        topImageName.onNext(ImagesAsset.Garry.con)
        headerLabelTitle.onNext(TextsAsset.MaintenanceLocationPopUp.title)
        subHeaderLabelTitle.onNext(TextsAsset.MaintenanceLocationPopUp.subtHeader)
        cancelButtonTitle.onNext(TextsAsset.MaintenanceLocationPopUp.cancelTitle)
        checkStatusButtonTitle.onNext(TextsAsset.MaintenanceLocationPopUp.checkStatus)
    }

    func cancel(vc: UIViewController?) {
        vc?.dismiss(animated: true)
    }

    func checkStatusAction(vc: WSNavigationViewController?) {
        vc?.openLink(url: Links.status)
    }
}

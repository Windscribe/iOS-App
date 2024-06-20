//
//  PopUpMaintenanceLocationModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 15/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol PopUpMaintenanceLocationModelType {
    var topImageName: BehaviorSubject<String> {get}
    var headerLabelTitle: BehaviorSubject<String> {get}
    var subHeaderLabelTitle: BehaviorSubject<String> {get}
    var cancelButtonTitle: BehaviorSubject<String> {get}
    var checkStatusButtonTitle: BehaviorSubject<String> {get}
    var isDarkMode: BehaviorSubject<Bool> {get}
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

    init(themeManager: ThemeManager) {
        isDarkMode = themeManager.darkTheme
        bindModel()
    }

    private func bindModel() {
        self.topImageName.onNext(ImagesAsset.Garry.con)
        self.headerLabelTitle.onNext(TextsAsset.MaintenanceLocationPopUp.title)
        self.subHeaderLabelTitle.onNext(TextsAsset.MaintenanceLocationPopUp.subtHeader)
        self.cancelButtonTitle.onNext(TextsAsset.MaintenanceLocationPopUp.cancelTitle)
        self.checkStatusButtonTitle.onNext(TextsAsset.MaintenanceLocationPopUp.checkStatus)
    }

    func cancel(vc: UIViewController?) {
        vc?.dismiss(animated: true)
    }

    func checkStatusAction(vc: WSNavigationViewController?) {
        vc?.openLink(url: Links.status)
    }
}

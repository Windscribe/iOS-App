//
//  MainViewController+CustomConfigPicker.swift
//  Windscribe
//
//  Created by Andre Fonseca on 07/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController {
    func bindCustomConfigPickerModel() {
        customConfigPickerViewModel.configureVPNTrigger.subscribe(onNext: {
            self.enableVPNConnection()
        }).disposed(by: disposeBag)

        customConfigPickerViewModel.displayAllertTrigger.subscribe(onNext: {
            switch $0 {
            case .connecting:
                self.displayConnectingAlert()
            case .disconnecting:
                self.displayDisconnectingAlert()
            }
        }).disposed(by: disposeBag)

        customConfigPickerViewModel.presentDocumentPickerTrigger.subscribe(onNext: {
            self.present($0, animated: true)
        }).disposed(by: disposeBag)

        customConfigPickerViewModel.showEditCustomConfigTrigger.subscribe(onNext: {
            self.popupRouter?.routeTo(to: .enterCredentials(config: $0.customConfig, isUpdating: $0.isUpdating), from: self)
        }).disposed(by: disposeBag)
    }
}

extension MainViewController: CustomConfigListViewDelegate {
    func hideCustomConfigRefreshControl() {
        if customConfigTableView.subviews.contains(customConfigsTableViewRefreshControl) {
            customConfigsTableViewRefreshControl.removeFromSuperview()
        }
        customConfigTableViewFooterView.isHidden = true
    }

    func showCustomConfigRefreshControl() {
        if !customConfigTableView.subviews.contains(customConfigsTableViewRefreshControl) {
            customConfigTableView.addSubview(customConfigsTableViewRefreshControl)
        }
        customConfigTableViewFooterView.isHidden = false
    }
}

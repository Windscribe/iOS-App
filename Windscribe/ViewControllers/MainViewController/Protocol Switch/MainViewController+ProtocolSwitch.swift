//
//  MainViewController+ProtocolSwitch.swift
//  Windscribe
//
//  Created by Andre on 16/05/2024.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

extension MainViewController {
    func bindProtocolSwitchViewModel() {
        protocolSwitchViewModel.configureVPNTrigger.subscribe { _ in
            self.enableVPNConnection()
        }.disposed(by: disposeBag)
    }
}

//
//  MainViewController+ProtocolSwitch.swift
//  Windscribe
//
//  Created by Andre on 16/05/2024.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

extension MainViewController {
    func bindProtocolSwitchViewModel() {
        protocolSwitchViewModel.configureVPNTrigger.subscribe({_ in
            self.configureVPN()
        }).disposed(by: disposeBag)
    }
}

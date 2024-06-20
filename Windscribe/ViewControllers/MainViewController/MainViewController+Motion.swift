//
//  MainViewController+Motion.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-14.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension MainViewController {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        let currentTimestamp = Date().timeIntervalSince1970
        if motion == .motionShake {
            if shakeDetected == 0 {
                self.firstShakeTimestamp = currentTimestamp
            }
            shakeDetected += 1
            if shakeDetected == 3 {
                self.lastShakeTimestamp = currentTimestamp
                if lastShakeTimestamp - firstShakeTimestamp < 10 {
                    self.shakeDetected = 0
                    popupRouter?.routeTo(to: RouteID.shakeForDataPopUp, from: self)
                } else {
                    self.shakeDetected = 0
                }
            }
        }
    }
}

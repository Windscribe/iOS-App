//
//  MainViewController+Motion.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-14.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension MainViewController {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with _: UIEvent?) {
        let currentTimestamp = Date().timeIntervalSince1970
        if motion == .motionShake {
            if shakeDetected == 0 {
                firstShakeTimestamp = currentTimestamp
            }
            shakeDetected += 1
            if shakeDetected == 3 {
                lastShakeTimestamp = currentTimestamp
                if lastShakeTimestamp - firstShakeTimestamp < 10 {
                    shakeDetected = 0
                    popupRouter?.routeTo(to: RouteID.shakeForDataPopUp, from: self)
                } else {
                    shakeDetected = 0
                }
            }
        }
    }
}

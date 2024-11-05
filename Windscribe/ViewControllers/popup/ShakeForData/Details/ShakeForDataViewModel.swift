//
//  ShakeForDataViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 22/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import AudioToolbox
import CoreMotion
import Foundation
import RxSwift

protocol ShakeForDataViewModelType {
    var shakeCount: BehaviorSubject<Int> { get }
    var timerCount: BehaviorSubject<Int> { get }
    var showResults: PublishSubject<Int> { get }
    var startTimerCount: Int { get }
    func wasShown()
    func quit()
}

class ShakeForDataViewModel: ShakeForDataViewModelType {
    var logger: FileLogger

    let startTimerCount = 60
    var shakeCount = BehaviorSubject<Int>(value: 0)
    var showResults = PublishSubject<Int>()
    lazy var timerCount = BehaviorSubject<Int>(value: startTimerCount)

    private let motionManager = CMMotionManager()
    private var countdownTimer: Timer?

    init(logger: FileLogger) {
        self.logger = logger
    }

    func wasShown() {
        logger.logD(self, "Displaying Shake For Data View")
        timerCount.onNext(startTimerCount)
        shakeCount.onNext(0)
        start()
    }

    func quit() {
        stopAccelerometers()
        countdownTimer?.invalidate()
    }
}

extension ShakeForDataViewModel {
    private func stopAccelerometers() {
        motionManager.stopDeviceMotionUpdates()
    }

    private func startAccelerometers() {
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedbackgenerator.prepare()
        var xInPositiveDirection = 0.0
        var xInNegativeDirection = 0.0
        motionManager.deviceMotionUpdateInterval = 0.01
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main,
                                               withHandler: { [weak self] data, _ in
                                                   if data!.userAcceleration.y > 3.0 || data!.userAcceleration.y < -3.0 {
                                                       if data!.userAcceleration.y > 3.0 {
                                                           xInNegativeDirection = 0.0
                                                           xInPositiveDirection = data!.userAcceleration.y
                                                       }

                                                       if data!.userAcceleration.y < -3.0 {
                                                           xInNegativeDirection = data!.userAcceleration.y
                                                       }

                                                       if xInPositiveDirection != 0.0, xInNegativeDirection != 0.0,
                                                          let prevValue = try? self?.shakeCount.value()
                                                       {
                                                           self?.shakeCount.onNext(prevValue + 1)
                                                           impactFeedbackgenerator.impactOccurred()
                                                           xInPositiveDirection = 0.0
                                                           xInNegativeDirection = 0.0
                                                       }
                                                   }
                                               })
    }

    private func start() {
        countdownTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateTimerCount),
            userInfo: nil,
            repeats: true
        )
        startAccelerometers()
    }

    @objc func updateTimerCount() {
        guard let currentCount = try? timerCount.value() else { return }
        if currentCount == 0 {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            countdownTimer?.invalidate()
            stopAccelerometers()

            let shakeCount = (try? shakeCount.value()) ?? 0
            showResults.onNext(shakeCount)
            return
        }
        timerCount.onNext(currentCount - 1)
    }
}

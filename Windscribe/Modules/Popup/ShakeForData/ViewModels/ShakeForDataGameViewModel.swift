//
//  ShakeForDataGameViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 18/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import CoreMotion
import Combine
import SwiftUI

protocol ShakeForDataGameViewModel: ObservableObject {
    var timeRemaining: Int { get }
    var shakeCount: Int { get }
    var gameEnded: Bool { get }
    var backgroundColor: Color { get }
    var shouldDismiss: Bool { get }
    var shouldNavigateToResults: Bool { get }

    func startGame()
    func handleShake()
    func quitGame()
}

class ShakeForDataGameViewModelImpl: ShakeForDataGameViewModel {
    @Published var timeRemaining: Int = 60
    @Published var shakeCount: Int = 0
    @Published var gameEnded: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var shouldNavigateToResults: Bool = false

    var backgroundColor: Color {
        if timeRemaining > 25 {
            return .brightBlue
        } else if timeRemaining > 5 {
            return .backgroundOrange
        } else {
            return .backgroundRed
        }
    }

    private var timer: Timer?
    private let motionManager = CMMotionManager()

    private let logger: FileLogger
    private let repository: ShakeDataRepository

    init(logger: FileLogger, repository: ShakeDataRepository) {
        self.logger = logger
        self.repository = repository
        startGame()
        startAccelerometers()
    }

    func startGame() {
        timer?.invalidate()
        timer = nil

        timeRemaining = 60
        shakeCount = 0
        gameEnded = false
        shouldNavigateToResults = false

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.timeRemaining -= 1

                if self.timeRemaining <= 0 {
                    self.endGame()
                }
            }
        }
    }

    func handleShake() {
        guard !gameEnded && timeRemaining > 0 else { return }
        shakeCount += 1
    }

    func quitGame() {
        timer?.invalidate()
        timer = nil
        motionManager.stopDeviceMotionUpdates()
        shouldDismiss = true
    }

    private func endGame() {
        timer?.invalidate()
        timer = nil
        motionManager.stopDeviceMotionUpdates()
        gameEnded = true

        repository.updateCurrentScore(shakeCount)

        shouldNavigateToResults = true
    }

    private func startAccelerometers() {
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedbackgenerator.prepare()
        var xInPositiveDirection = 0.0
        var xInNegativeDirection = 0.0
        motionManager.deviceMotionUpdateInterval = 0.01
        motionManager.startDeviceMotionUpdates(
            to: OperationQueue.main,
            withHandler: { [weak self] data, _ in
                guard let self = self else { return }
                if data!.userAcceleration.y > 3.0 || data!.userAcceleration.y < -3.0 {
                    if data!.userAcceleration.y > 3.0 {
                        xInNegativeDirection = 0.0
                        xInPositiveDirection = data!.userAcceleration.y
                    }
                    if data!.userAcceleration.y < -3.0 {
                        xInNegativeDirection = data!.userAcceleration.y
                    }
                    if xInPositiveDirection != 0.0, xInNegativeDirection != 0.0 {
                        self.shakeCount += 1
                        impactFeedbackgenerator.impactOccurred()
                        xInPositiveDirection = 0.0
                        xInNegativeDirection = 0.0
                    }
                }
            })
    }

    deinit {
        timer?.invalidate()
        motionManager.stopDeviceMotionUpdates()
    }
}

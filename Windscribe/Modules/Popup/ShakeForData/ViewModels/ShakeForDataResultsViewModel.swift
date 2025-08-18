//
//  ShakeForDataResultsViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

protocol ShakeForDataResultsViewModel: ObservableObject {
    var isDarkMode: Bool { get }
    var finalScore: Int { get }
    var isNewHighScore: Bool { get }
    var apiMessage: String { get }

    func checkForHighScore()
}

class ShakeForDataResultsViewModelImpl: ShakeForDataResultsViewModel {
    @Published var finalScore: Int = 0
    @Published var isDarkMode: Bool = false
    @Published var isNewHighScore: Bool = false
    @Published var apiMessage: String = ""

    private var cancellables = Set<AnyCancellable>()

    private let logger: FileLogger
    private let preferences: Preferences
    private let repository: ShakeDataRepository
    private let lookAndFeelRepository: LookAndFeelRepositoryType

    init(preferences: Preferences,
         logger: FileLogger,
         repository: ShakeDataRepository,
         lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.preferences = preferences
        self.logger = logger
        self.repository = repository
        self.lookAndFeelRepository = lookAndFeelRepository

        checkForHighScore()
        isDarkMode = lookAndFeelRepository.isDarkMode
    }

    func checkForHighScore() {
        // Get the final score from the repository
        finalScore = repository.currentScore

        let currentHighScore = preferences.getShakeForDataHighestScore() ?? 0

        if finalScore > currentHighScore {
            isNewHighScore = true
            preferences.saveShakeForDataHighestScore(score: finalScore)
            repository.recordShakeForDataScore(score: finalScore)
                .asPublisher()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in
                }, receiveValue: { [weak self] message in
                    self?.apiMessage = message
                })
                .store(in: &cancellables)
        } else {
            isNewHighScore = false
        }
    }
}

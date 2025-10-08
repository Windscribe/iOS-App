//
//  ShakeForDataLeaderboardModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 17/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol ShakeForDataLeaderboardModel: ObservableObject {
    var isDarkMode: Bool { get }
    var leaderboardEntries: [ShakeForDataLeaderboardEntry] { get }
}

class ShakeForDataLeaderboardModelImpl: ShakeForDataLeaderboardModel {
    @Published var isDarkMode: Bool = false
    @Published var leaderboardEntries: [ShakeForDataLeaderboardEntry] = []

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let repository: ShakeDataRepository

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         repository: ShakeDataRepository) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.repository = repository
        bindSubjects()
    }

    private func bindSubjects() {
        isDarkMode = lookAndFeelRepository.isDarkMode

        repository.getLeaderboardScores()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ShakeForDataLeaderboardModelImpl", "Getting the scores, error: \(error)")
                }
            }, receiveValue: { [weak self] scores in
                self?.leaderboardEntries = scores.map { $0.toLeaderboardEntry() }
            })
            .store(in: &cancellables)
    }

    private func checkDarkMode() {
        // Check current color scheme
        isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    }
}

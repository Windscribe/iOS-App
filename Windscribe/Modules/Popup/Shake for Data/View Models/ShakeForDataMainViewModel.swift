//
//  ShakeForDataMainViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 11/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol ShakeForDataMainViewModel: ObservableObject {
    var isDarkMode: Bool { get }

    func startShaking()
    func viewLeaderboard()
    func dismissFreeStuff()
}

class ShakeForDataMainViewModelImpl: ShakeForDataMainViewModel {
    @Published var isDarkMode: Bool = true

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository

        isDarkMode = lookAndFeelRepository.isDarkMode
    }

    func startShaking() {
        // Handle start shaking logic
        print("Start shaking tapped")
    }

    func viewLeaderboard() {
        // Handle view leaderboard logic
    }

    func dismissFreeStuff() {
        // Handle dismiss free stuff logic
        print("I hate free stuff tapped")
    }
}

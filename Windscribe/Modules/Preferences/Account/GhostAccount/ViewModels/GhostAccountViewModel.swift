//
//  GhostAccountViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-09.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import Foundation

protocol GhostAccountViewModel: ObservableObject {
    var isUserPro: Bool { get }
    var isDarkMode: Bool { get set }
}

class GhostAccountViewModelImpl: GhostAccountViewModel {

    var isUserPro: Bool {
        userSessionRepository.sessionModel?.isUserPro ?? false
    }

    @Published var isDarkMode: Bool = false

    private let userSessionRepository: UserSessionRepository
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()

    init(userSessionRepository: UserSessionRepository,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         logger: FileLogger) {
        self.userSessionRepository = userSessionRepository
        self.lookAndFeelRepository = lookAndFeelRepository
        self.logger = logger

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
            }
            .store(in: &cancellables)
    }
}

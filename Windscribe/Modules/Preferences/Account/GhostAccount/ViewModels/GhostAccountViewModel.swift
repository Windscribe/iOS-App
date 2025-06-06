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
        sessionManager.session?.isUserPro ?? false
    }

    @Published var isDarkMode: Bool = false

    private let sessionManager: SessionManaging
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()

    init(sessionManager: SessionManaging,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         logger: FileLogger) {
        self.sessionManager = sessionManager
        self.lookAndFeelRepository = lookAndFeelRepository
        self.logger = logger

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("GhostAccountViewModel", "darkTheme error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
            .store(in: &cancellables)
    }
}
